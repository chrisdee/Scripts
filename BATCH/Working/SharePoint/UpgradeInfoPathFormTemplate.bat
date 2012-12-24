::BATCH script to update / upgrade an infopath form template, and activate it for a particular site collection (uses STSADM commands)
cd C:\Program Files\Common Files\Microsoft Shared\web server extensions\12\BIN
stsadm.exe -o DeActivateFormTemplate -url http://demosite -filename C:\InfoPathForms\Publish\sample.xsn
stsadm.exe -o verifyformtemplate -filename C:\InfoPathForms\Publish\sample.xsn
stsadm.exe -o UpgradeFormTemplate -filename C:\InfoPathForms\Publish\sample.xsn
stsadm.exe -o execadmsvcjobs
stsadm.exe -o ActivateFormTemplate -url http://demosite -filename C:\InfoPathForms\Publish\sample.xsn