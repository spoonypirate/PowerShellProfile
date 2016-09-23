Sub filter(Item As Outlook.MailItem)
    Dim ns As Outlook.NameSpace
    Dim myInbox As Outlook.Folder
    Dim MailDest As Outlook.Folder
    Set ns = Application.GetNamespace("MAPI")
    Set myInbox = ns.GetDefaultFolder(olFolderInbox)
    Set Reg1 = CreateObject("VBScript.RegExp")
    Reg1.Global = True
    Reg1.Pattern = "(Case [\d].+your team.)"
    If Reg1.Test(Item.Subject) Then
        Set MailDest = myInbox.Folders("Tickets")
        Item.Move MailDest
    End If
End Sub