;{- F1 Test for the Ldb library ( Little Database )
 ; launch it in debug mode
 
 ; Create a new Database with 3 fields
 LdbCreate("c:\Drivers.db","Birth Date,Name,Surname")
  LdbOpen("c:\Drivers.db")
 
 ; Add one Record
 LdbInsertRecord(-1)
 ; Write data to this record
 LdbWrite(1,"1969") ; 1st field
 LdbWrite(2,"schumacher") ; 2nd field
 LdbWrite(3,"Mikael") ; 3rd field
 
 ; Add another Record
 LdbInsertRecord(-1)
 ; Write data to this record
 LdbWrite(1,"1980") ; 1st field
 LdbWrite(2,"Button") ; 2nd field
 LdbWrite(3,"Jenson") ; 3rd field
 
 ; Add another Record
 LdbInsertRecord(-1)
 ; Write data to this record
 LdbWrite(1,"1981") ; 1st field
 LdbWrite(2,"Alonso") ; 2nd field
 LdbWrite(3,"Fernando") ; 3rd field
 
 ; Add another Record
 LdbInsertRecord(-1)
 ; Write data to this record
 LdbWrite(1,"1971") ; 1st field
 LdbWrite(2,"Villeneuve") ; 2nd field
 LdbWrite(3,"Jacques") ; 3rd field
 
 ; Insert a record at 3rd position
 LdbInsertRecord(3)
 ; Write data to this record
 LdbWrite(1,"1975") ; 1st field
 LdbWrite(2,"Schumacher") ; 2nd field
 LdbWrite(3,"Ralph") ; 3rd field
 
 ; Sort the database by field 1 ( Birth Date )
 LdbSortNum(1)
 
 ; Show all drivers sorted by birth Date
 Debug "Drivers sorted by birth date"
 For n=1 To LdbCountRecord()
  LdbSetPointer(n)
  Debug LdbRead(1)+" "+LdbRead(2)+" "+LdbRead(3)
 Next
 Debug ""
 
 ; Sort the database by Drivers names
 LdbSortAlpha(2,1)
 
 ; Show all drivers sorted by name
 Debug "Drivers sorted by name"
 For n=1 To LdbCountRecord()
  LdbSetPointer(n)
  Debug LdbRead(1)+" "+LdbRead(2)+" "+LdbRead(3)
 Next
 Debug ""
 
 ; Search all name = Schumacher
 LdbSearchInit(2,"Schumacher",1)
 
 ; Show all drivers = Schumacher
 Debug "Drivers with name = Schumacher"
 Repeat
  Champ=LdbSearch()
  If Champ=0 : Break : EndIf ; if 0 --> search finished
  LdbSetPointer(Champ)
  Debug LdbRead(1)+" "+LdbRead(2)+" "+LdbRead(3)
 ForEver
 Debug ""
 
 ; Database Infos
 Debug "Database Infos"
 Debug "Number of fields "+Str(LdbCountField())
 Debug "Name of field"
 For n=1 To LdbCountField()
  Debug "Field n° "+Str(n)+" = "+LdbGetFieldName(n)
 Next
 
 Debug "Number of records "+Str(LdbCountRecord())
 
 ; Save Database to disk
 LdbSaveDatabase()
 ; Close the Database
 LdbCloseDatabase()
;}

; IDE Options = PureBasic v4.02 (Windows - x86)
; CursorPosition = 88
; FirstLine = 33
; Folding = -