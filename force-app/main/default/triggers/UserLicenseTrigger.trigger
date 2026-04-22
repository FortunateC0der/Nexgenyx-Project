trigger UserLicenseTrigger on User (after insert) {
    if (Trigger.isInsert && Trigger.isAfter) {
        UserLicenseHandler.assignOmniStudioLicenses(Trigger.new);
    }
}