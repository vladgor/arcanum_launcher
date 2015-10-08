@echo off
undat arcanum4.dat -l
undat arcanum4.dat undat\
undat modules\arcanum.patch0 -l
undat modules\arcanum.patch0 undat\
undat modules\vormantown.patch0 -l
undat modules\vormantown.patch0 undat\
echo Все файлы Grand Fix'а распакованы из DAT архивов в директории, 
echo созданы соответствующие архивам лист файлы: 
echo arcanum4.dat в "undat\arcanum4", лист файл - arcanum4.lst; 
echo arcanum.patch0 в "undat\arcanum", лист файл -  arcanum.lst; 
echo vormantown.patch0 в "undat\vormantown", лист файл -  vormantown.lst. 
echo Если хотите, то можете полюбопытствовать. ;) 