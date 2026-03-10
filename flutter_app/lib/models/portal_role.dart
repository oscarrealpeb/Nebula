enum PortalRole {
  child,
  caregiver,
  admin,
}

extension PortalRoleLabel on PortalRole {
  String get storageValue => name;

  String get label {
    switch (this) {
      case PortalRole.child:
        return 'Ni\u00f1o';
      case PortalRole.caregiver:
        return 'Cuidador';
      case PortalRole.admin:
        return 'Admin';
    }
  }

  static PortalRole fromStorageValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'child':
        return PortalRole.child;
      case 'admin':
        return PortalRole.admin;
      case 'caregiver':
      default:
        return PortalRole.caregiver;
    }
  }
}
