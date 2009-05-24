FontsGen -ttf=simsun  -destdir=.. -CJKname=song -stemv=50  %1 %2
FontsGen -ttf=simkai  -destdir=.. -CJKname=kai  -stemv=70  %1 %2
FontsGen -ttf=simhei  -destdir=.. -CJKname=hei  -stemv=150 %1 %2
FontsGen -ttf=simfang -destdir=.. -CJKname=fs   -stemv=50  %1 %2
FontsGen -ttf=simli   -destdir=.. -CJKname=li   -stemv=150 %1 %2
FontsGen -ttf=simyou  -destdir=.. -CJKname=you  -stemv=60  %1 %2
                                  
FontsGen -ttf=simsun  -destdir=.. -CJKname=song -encoding=UTF8 -stemv=50   %1 %2
FontsGen -ttf=simkai  -destdir=.. -CJKname=kai  -encoding=UTF8 -stemv=70   %1 %2
FontsGen -ttf=simhei  -destdir=.. -CJKname=hei  -encoding=UTF8 -stemv=150  %1 %2
FontsGen -ttf=simfang -destdir=.. -CJKname=fs   -encoding=UTF8 -stemv=50   %1 %2
FontsGen -ttf=simli   -destdir=.. -CJKname=li   -encoding=UTF8 -stemv=150  %1 %2
FontsGen -ttf=simyou  -destdir=.. -CJKname=you  -encoding=UTF8 -stemv=60   %1 %2
                                                              
mkdir ..\fonts\sfd
copy .\*.sfd ..\fonts\sfd