"use strict";

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const vision = require("@google-cloud/vision");

setGlobalOptions({
  region: "us-central1",
  memory: "512MiB",
  timeoutSeconds: 30,
  maxInstances: 10,
});

const visionClient = new vision.ImageAnnotatorClient();
const maxImageBytes = 5 * 1024 * 1024;
const maxBase64Chars = Math.ceil(maxImageBytes * 4 / 3) + 1024;

exports.reviewCustomImage = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesion para validar imagenes.",
    );
  }

  const data = request.data || {};
  const imageBase64 = String(data.imageBase64 || "").trim();
  const gameKey = normalize(data.gameKey);
  const itemId = normalize(data.itemId);
  const expectedConcepts = Array.isArray(data.expectedConcepts) ?
    data.expectedConcepts.map(normalize).filter(Boolean) :
    [];
  const expectedEmotion = normalize(data.expectedEmotion);
  const expectedDescription = String(data.expectedDescription || "").trim();

  if (!imageBase64) {
    throw new HttpsError(
        "invalid-argument",
        "No encontramos la imagen a revisar.",
    );
  }

  if (imageBase64.length > maxBase64Chars) {
    throw new HttpsError(
        "invalid-argument",
        "La imagen es demasiado grande para revisarla.",
    );
  }

  let imageBuffer;
  try {
    imageBuffer = Buffer.from(imageBase64, "base64");
  } catch (_) {
    throw new HttpsError(
        "invalid-argument",
        "No pudimos leer la imagen enviada.",
    );
  }

  if (!imageBuffer.length || imageBuffer.length > maxImageBytes) {
    throw new HttpsError(
        "invalid-argument",
        "La imagen no es valida o supera el tamano permitido.",
    );
  }

  const features = [
    {type: "SAFE_SEARCH_DETECTION", maxResults: 1},
    {type: "LABEL_DETECTION", maxResults: 12},
    {type: "OBJECT_LOCALIZATION", maxResults: 12},
  ];

  if (gameKey === "emociones" && expectedEmotion) {
    features.push({type: "FACE_DETECTION", maxResults: 5});
  }

  try {
    const [result] = await visionClient.annotateImage({
      image: {content: imageBuffer},
      features,
    });

    const unsafeCategories = getUnsafeCategories(result.safeSearchAnnotation || {});
    if (unsafeCategories.length) {
      return {
        ok: false,
        message: `La imagen parece no ser apropiada para contenido infantil (${unsafeCategories.join(", ")}).`,
        reviewed: true,
      };
    }

    if (gameKey === "emociones" && expectedEmotion) {
      const faceAnnotations = Array.isArray(result.faceAnnotations) ?
        result.faceAnnotations :
        [];
      if (!faceAnnotations.length) {
        return {
          ok: false,
          message: "La imagen no parece mostrar un rostro claro para esta actividad.",
          reviewed: true,
        };
      }
      if (!matchesExpectedEmotion(faceAnnotations, expectedEmotion)) {
        return {
          ok: false,
          message: `La imagen no parece corresponder a la emocion esperada (${expectedDescription || expectedEmotion}).`,
          reviewed: true,
        };
      }
      return {ok: true, reviewed: true};
    }

    if (expectedConcepts.length) {
      const candidateLabels = getCandidateLabels(result);
      const expectedAliases = getExpectedAliases(expectedConcepts);
      if (!matchesExpectedConcept(candidateLabels, expectedAliases)) {
        return {
          ok: false,
          message: `La imagen no parece corresponder al elemento esperado (${expectedDescription || expectedConcepts[0]}).`,
          reviewed: true,
        };
      }
    }

    return {ok: true, reviewed: true};
  } catch (error) {
    logger.error("reviewCustomImage failed", {
      uid: request.auth.uid,
      gameKey,
      itemId,
      error: error instanceof Error ? error.message : String(error),
    });
    throw new HttpsError(
        "internal",
        "No pudimos validar la imagen en este momento.",
    );
  }
});

function getUnsafeCategories(safeSearch) {
  const flagged = [];
  if (likelihood(safeSearch.adult) >= 3) flagged.push("adulto");
  if (likelihood(safeSearch.racy) >= 3) flagged.push("contenido sugestivo");
  if (likelihood(safeSearch.violence) >= 3) flagged.push("violencia");
  return flagged;
}

function matchesExpectedEmotion(faceAnnotations, expectedEmotion) {
  let strongestJoy = 0;
  let strongestSorrow = 0;
  let strongestAnger = 0;
  let strongestSurprise = 0;

  for (const face of faceAnnotations) {
    strongestJoy = Math.max(strongestJoy, likelihood(face.joyLikelihood));
    strongestSorrow = Math.max(
        strongestSorrow,
        likelihood(face.sorrowLikelihood),
    );
    strongestAnger = Math.max(
        strongestAnger,
        likelihood(face.angerLikelihood),
    );
    strongestSurprise = Math.max(
        strongestSurprise,
        likelihood(face.surpriseLikelihood),
    );
  }

  switch (expectedEmotion) {
    case "feliz":
      return strongestJoy >= 3;
    case "triste":
      return strongestSorrow >= 3;
    case "enojado":
      return strongestAnger >= 3;
    case "sorprendido":
      return strongestSurprise >= 3;
    case "asustado":
      return strongestSurprise >= 3 || strongestSorrow >= 4;
    default:
      return true;
  }
}

function getCandidateLabels(result) {
  const labels = new Set();
  const labelAnnotations = Array.isArray(result.labelAnnotations) ?
    result.labelAnnotations :
    [];
  const objectAnnotations = Array.isArray(result.localizedObjectAnnotations) ?
    result.localizedObjectAnnotations :
    [];

  for (const item of labelAnnotations) {
    const value = normalize(item.description);
    if (value) labels.add(value);
  }
  for (const item of objectAnnotations) {
    const value = normalize(item.name);
    if (value) labels.add(value);
  }
  return labels;
}

function getExpectedAliases(expectedConcepts) {
  const aliases = new Set();
  for (const concept of expectedConcepts) {
    const normalized = normalize(concept);
    if (!normalized) continue;
    aliases.add(normalized);
    const extra = conceptAliasMap[normalized] || [];
    for (const alias of extra) {
      const aliasNormalized = normalize(alias);
      if (aliasNormalized) aliases.add(aliasNormalized);
    }
  }
  return aliases;
}

function matchesExpectedConcept(candidateLabels, expectedAliases) {
  if (!expectedAliases.size) return true;
  for (const candidate of candidateLabels) {
    for (const alias of expectedAliases) {
      if (candidate === alias) return true;
      if (candidate.includes(alias) && alias.length >= 3) return true;
      if (alias.includes(candidate) && candidate.length >= 3) return true;
    }
  }
  return false;
}

function likelihood(value) {
  switch (String(value || "").trim().toUpperCase()) {
    case "VERY_UNLIKELY":
      return 1;
    case "UNLIKELY":
      return 2;
    case "POSSIBLE":
      return 3;
    case "LIKELY":
      return 4;
    case "VERY_LIKELY":
      return 5;
    default:
      return 0;
  }
}

function normalize(value) {
  return String(value || "")
      .trim()
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z0-9 ]+/g, " ")
      .replace(/\s+/g, " ")
      .trim();
}

const conceptAliasMap = {
  "perro": ["dog", "puppy", "canine"],
  "gato": ["cat", "kitten", "feline"],
  "caballo": ["horse", "equine"],
  "ballena": ["whale", "cetacean"],
  "buho": ["owl"],
  "burro": ["donkey", "ass"],
  "delfin": ["dolphin"],
  "elefante": ["elephant"],
  "gallo": ["rooster", "chicken"],
  "grillo": ["cricket", "insect"],
  "pato": ["duck"],
  "vaca": ["cow", "cattle"],
  "guitarra": ["guitar"],
  "arpa": ["harp"],
  "piano": ["piano", "keyboard"],
  "violin": ["violin", "fiddle"],
  "olas": ["wave", "ocean", "sea", "water"],
  "aspiradora": ["vacuum", "vacuum cleaner"],
  "microondas": ["microwave", "microwave oven"],
  "puerta": ["door"],
  "bebe": ["baby", "infant", "toddler"],
  "aplausos": ["applause", "clapping", "audience"],
  "claxon": ["horn", "car horn"],
  "centro comercial": ["shopping mall", "mall", "shopping center"],
  "restaurante": ["restaurant", "dining room", "cafe"],
  "ninos": ["children", "child", "kid", "kids"],
  "tormenta": ["storm", "thunderstorm", "lightning", "rain"],
  "coro": ["choir", "chorus", "singing"],
  "durazno": ["peach", "fruit"],
  "freijoas": ["feijoa", "fruit"],
  "mango": ["mango", "fruit"],
  "naranja": ["orange", "fruit"],
  "uva": ["grape", "fruit"],
};
