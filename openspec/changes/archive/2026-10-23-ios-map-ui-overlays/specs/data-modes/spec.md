# Spec Delta

## REMOVED Requirements

### Requirement: Count threshold filtering
**Reason**: The app never exposed a way to set the count threshold and always requested with it inactive, so this requirement described behaviour no user could reach. The map chrome phase replaces the request placeholders with real controls, and a threshold that nothing can set would only be carried into the new legend as a line that can never appear.
**Migration**: None. Only the inactive value was ever sent, so request results and displayed data are unchanged. The provider protocol still expects the threshold argument in its fixed position, so the app keeps sending that argument as a constant rather than removing it from the request.
