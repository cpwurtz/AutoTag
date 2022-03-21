﻿param($eventGridEvent, $TriggerMetadata)

$eventGridEvent | Out-String | Write-Host

Write-Host "## eventGridEvent.json ##"

$eventGridEvent | convertto-json | Write-Host

# Get the day in Month Day Year format

$dateCreated = Get-Date -UFormat "%m/%d/%Y"
$dateModified = Get-Date -UFormat "%m/%d/%Y"
$dateExpiry = (Get-Date).AddYears(1) | Get-Date -UFormat "%m/%d/%Y"
$Environment = (Get-AzContext).Subscription.Name
# Add tag and value to the resource CHANGE ENVIRONMET!!

$nameValue = $eventGridEvent.data.claims.name
$upnValue = $eventGridEvent.data.claims.'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn'
$appID = $eventGridEvent.data.claims.appid

#$creationTags = @{"CreatedBy"="$nameValue, $upnValue";"DateCreated"="$dateCreated";"Environment"="SANDBOX"}
#$modifiedTags = @{"LastModifiedBy"="$nameValue, $upnValue";"DateLastModified"="$dateModified"}

If ($upnValue) {
$creationTags = @{"CreatedBy"="$nameValue, $upnValue";"DateCreated"="$dateCreated";"ReviewDate"="$dateExpiry";"Environment"="$Environment"}
$modifiedTags = @{"LastModifiedBy"="$nameValue, $upnValue";"DateLastModified"="$dateModified"}
} else {
$creationTags = @{"CreatedBy"="$appID";"DateCreated"="$dateCreated";"ReviewDate"="$dateExpiry";"Environment"="$Environment"}
$modifiedTags = @{"LastModifiedBy"="$appID";"DateLastModified"="$dateModified"}
}

write-output "Creation Tags:"
write-output $tags
write-output "Modified Tags:"
write-output $modifiedTags

# Resource Group Information:

$resourceURI = $eventGridEvent.data.resourceUri

write-output "Resource URI:"
write-output $resourceURI

$tags = (Get-AzTag -resourceid $resourceURI).Properties.TagsProperty.keys

if ($tags.Contains('Creator') -or $tags.Contains('DateCreated'))
{
write-host 'creation tags exist, writing modified'
Update-AzTag -ResourceId $resourceURI -Tag $modifiedTags -operation Merge -ErrorAction Stop
}
else
{
Try {
write-host 'writing creation tags'
Update-AzTag -ResourceId $resourceURI -Tag $creationTags -operation Merge -ErrorAction Stop
}
Catch
{
$ErrorMessage = $_.Exception.message
write-host ('Error assigning tags ' + $ErrorMessage)
Break
}
}
