public class UserLicenseHandler { 

    // ─── Called from trigger ──────────────────────────────────────────────────
    public static void assignOmniStudioLicenses(List<User> newUsers) {
        Set<Id> userIds = new Set<Id>();
        for (User u : newUsers) {
            if (!u.IsActive || u.UserType == 'Guest') continue;
            userIds.add(u.Id);
        }
        if (!userIds.isEmpty()) {
            assignLicensesAndPermissionsAsync(userIds);
        }
    }

    // ─── Single async method — licenses first, then permission sets ───────────
    @future
    public static void assignLicensesAndPermissionsAsync(Set<Id> userIds) {

        List<User> users = [
            SELECT Id, IsActive, UserType 
            FROM User 
            WHERE Id IN :userIds
        ];

        // ── Step 1: Permission Set Licenses ───────────────────────────────────

        Map<String, PermissionSetLicense> licenseMap = new Map<String, PermissionSetLicense>(); 
        for (PermissionSetLicense psl : [ 
            SELECT Id, MasterLabel, TotalLicenses, UsedLicenses 
            FROM PermissionSetLicense 
            WHERE MasterLabel IN ( 
                'Mortgage',
                'OmniStudio',
                'OmniStudio Runtime for Communities',
                'OmniStudio User'
            ) 
        ]) { 
            licenseMap.put(psl.MasterLabel, psl); 
        }

        Set<String> existingLicenseKeys = new Set<String>();
        for (PermissionSetLicenseAssign existing : [
            SELECT AssigneeId, PermissionSetLicenseId
            FROM PermissionSetLicenseAssign
            WHERE AssigneeId IN :userIds
        ]) {
            existingLicenseKeys.add(existing.AssigneeId + '_' + existing.PermissionSetLicenseId);
        }

        List<PermissionSetLicenseAssign> licenseAssignments = new List<PermissionSetLicenseAssign>(); 
        for (User u : users) { 
            if (!u.IsActive || u.UserType == 'Guest') continue; 

            for (PermissionSetLicense psl : licenseMap.values()) { 
                if (psl.UsedLicenses < psl.TotalLicenses) {
                    String key = u.Id + '_' + psl.Id;
                    if (!existingLicenseKeys.contains(key)) {
                        licenseAssignments.add(new PermissionSetLicenseAssign( 
                            AssigneeId = u.Id, 
                            PermissionSetLicenseId = psl.Id 
                        ));
                        existingLicenseKeys.add(key);
                    }
                } 
            } 
        } 

        if (!licenseAssignments.isEmpty()) { 
            insert licenseAssignments; 
        }

        // ── Step 2: Permission Sets ───────────────────────────────────────────

        Set<String> psLabels = new Set<String>{
            'Omnistudio Admin',
            'Omnistudio User',
            'Borrower Portal Access',
            'Community User Plus Omni Access',
            'Customer Community Plus User Clone',
                'OmniStudio Access'
 
        };

        Map<String, PermissionSet> psMap = new Map<String, PermissionSet>();
        for (PermissionSet ps : [
            SELECT Id, Label
            FROM PermissionSet 
            WHERE Label IN :psLabels
        ]) {
            psMap.put(ps.Label, ps);
        }

        Set<String> existingPsKeys = new Set<String>();
        for (PermissionSetAssignment existing : [
            SELECT AssigneeId, PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId IN :userIds 
              AND PermissionSet.Label IN :psLabels
        ]) {
            existingPsKeys.add(existing.AssigneeId + '_' + existing.PermissionSetId);
        }

        List<PermissionSetAssignment> psAssignments = new List<PermissionSetAssignment>();
        for (User u : users) {
            if (!u.IsActive || u.UserType == 'Guest') continue;

            for (PermissionSet ps : psMap.values()) {
                String key = u.Id + '_' + ps.Id;
                if (!existingPsKeys.contains(key)) {
                    psAssignments.add(new PermissionSetAssignment(
                        AssigneeId = u.Id,
                        PermissionSetId = ps.Id
                    ));
                    existingPsKeys.add(key);
                }
            }
        }

        if (!psAssignments.isEmpty()) {
            insert psAssignments;
        }
    }
}