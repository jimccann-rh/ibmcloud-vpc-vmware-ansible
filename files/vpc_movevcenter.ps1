#!/usr/bin/pwsh

Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -Confirm:$false | Out-Null


$VMhost = $args[0]
$vCenter = $args[1]
$vpc = $args[2]
$vcenter_dvs = $args[3]
$vcenter_dvs_dpg = $args[4]
$vswitch_pg = $args[5]
$VMname = $args[6]

$Username = Get-Content "~/$vpc/vcenter-username.txt"
$Password = Get-Content "~/$vpc/vcenter-password.txt" | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential $Username,$Password

Connect-VIServer -Server $vCenter -Credential $Credentials


$esx = Get-VMHost -Name $VMhost
$esxdata = $esx | Select -ExpandProperty ExtensionData | select -ExpandProperty moref
$vm = get-vm $VMname
$vmnet = $vm | Get-NetworkAdapter
$vmnettype = $vmnet | Select -ExpandProperty ExtensionData
$vdspg = Get-VDPortgroup -VDSwitch $vcenter_dvs -Name $vcenter_dvs_dpg
$respool = Get-ResourcePool
$respdata = $respool | Select -ExpandProperty ExtensionData | select -ExpandProperty moref
$vds = Get-VDSwitch
$datastoredata = Get-Datastore | Select -ExpandProperty ExtensionData | Where-Object {$_.moref -Match $esx.DatastoreIdList} | select -ExpandProperty moref

write-host "switch id" $vds.key
write-host "switch pg" $vdspg.key
write-host "datastore" $datastoredata.value
write-host "host" $esxdata.value
write-host "host" $esxdata
write-host "host" $esx.name
write-host "vm" $vm
write-host "vmid" $vm.id
write-host "vmmac" $vmnet.MacAddress
write-host "vm power should be ON" $vm.powerstate
write-host "resource" $respdata.value
write-host "resource" $respdata
write-host "res pool" $respool


$spec = New-Object VMware.Vim.VirtualMachineRelocateSpec
$spec.Disk = New-Object VMware.Vim.VirtualMachineRelocateSpecDiskLocator[] (1)
$spec.Disk[0] = New-Object VMware.Vim.VirtualMachineRelocateSpecDiskLocator
$spec.Disk[0].Datastore = New-Object VMware.Vim.ManagedObjectReference
$spec.Disk[0].Datastore.Type = 'Datastore'
$spec.Disk[0].Datastore.Value = $datastoredata.value
$spec.Disk[0].DiskId = 2000
$spec.Datastore = New-Object VMware.Vim.ManagedObjectReference
$spec.Datastore.Type = 'Datastore'
$spec.Datastore.Value = $datastoredata.value
$spec.DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (1)
$spec.DeviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
$spec.DeviceChange[0].Device = New-Object VMware.Vim.VirtualVmxnet3
$spec.DeviceChange[0].Device.MacAddress = $vmnet.MacAddress
$spec.DeviceChange[0].Device.ResourceAllocation = New-Object VMware.Vim.VirtualEthernetCardResourceAllocation
$spec.DeviceChange[0].Device.ResourceAllocation.Limit = -1
$spec.DeviceChange[0].Device.ResourceAllocation.Reservation = 0
$spec.DeviceChange[0].Device.ResourceAllocation.Share = New-Object VMware.Vim.SharesInfo
$spec.DeviceChange[0].Device.ResourceAllocation.Share.Shares = 50
$spec.DeviceChange[0].Device.ResourceAllocation.Share.Level = 'normal'
$spec.DeviceChange[0].Device.Connectable = New-Object VMware.Vim.VirtualDeviceConnectInfo
$spec.DeviceChange[0].Device.Connectable.Connected = $true
$spec.DeviceChange[0].Device.Connectable.MigrateConnect = 'unset'
$spec.DeviceChange[0].Device.Connectable.AllowGuestControl = $true
$spec.DeviceChange[0].Device.Connectable.StartConnected = $true
$spec.DeviceChange[0].Device.Connectable.Status = 'ok'
$spec.DeviceChange[0].Device.Backing = New-Object VMware.Vim.VirtualEthernetCardDistributedVirtualPortBackingInfo
$spec.DeviceChange[0].Device.Backing.Port = New-Object VMware.Vim.DistributedVirtualSwitchPortConnection
$spec.DeviceChange[0].Device.Backing.Port.SwitchUuid = $vds.key
$spec.DeviceChange[0].Device.Backing.Port.PortgroupKey = $vdspg.key
#$spec.DeviceChange[0].Device.AddressType = 'assigned'
$spec.DeviceChange[0].Device.AddressType = $vmnettype.AddressType
$spec.DeviceChange[0].Device.ControllerKey = 100
$spec.DeviceChange[0].Device.UnitNumber = 7
$spec.DeviceChange[0].Device.WakeOnLanEnabled = $true
$spec.DeviceChange[0].Device.SlotInfo = New-Object VMware.Vim.VirtualDevicePciBusSlotInfo
$spec.DeviceChange[0].Device.SlotInfo.PciSlotNumber = 192
$spec.DeviceChange[0].Device.UptCompatibilityEnabled = $true
$spec.DeviceChange[0].Device.DeviceInfo = New-Object VMware.Vim.Description
$spec.DeviceChange[0].Device.DeviceInfo.Summary = $vswitch_pg
$spec.DeviceChange[0].Device.DeviceInfo.Label = 'Network adapter 1'
$spec.DeviceChange[0].Device.Key = 4000
$spec.DeviceChange[0].Operation = 'edit'
$spec.Host = New-Object VMware.Vim.ManagedObjectReference
$spec.Host.Type = 'HostSystem'
$spec.Host.Value = $esxdata.value
$spec.Pool = New-Object VMware.Vim.ManagedObjectReference
$spec.Pool.Type = 'ResourcePool'
$spec.Pool.Value = $respdata.value
$priority = 'highPriority'
$_this = Get-View -Id $vm.id
$_this.RelocateVM_Task($spec, $priority)

Start-Sleep -Seconds 300
