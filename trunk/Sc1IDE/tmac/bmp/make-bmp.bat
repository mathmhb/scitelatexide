REM ���б�����ǰ�뽫MiCTeX 2.55��TexFriend\texsource�е�tex�ļ��������ļ�����Ŀ¼��Ȼ��������б��ļ���������ֱ��ʵ�ͼƬ��
::copy "D:\MiCTeX\Misc Tools\TexFriend\texsource\*.tex" .
xchange *.tex "{article}" "{article}\pagestyle{empty}"
xchange *.tex "\def\vvspace{" "\def\vvspace{}%%"
xchange *.tex "\selectfont H}" "\selectfont \phantom{H}}"

xchange *.tex "abc^13,^10" "%%abc ^13,^10"
xchange *.tex "$\mathbb{\bbalpha}$" "%%$\mathbb{\bbalpha}$"
xchange *.tex  "\[ab\]^10,a" "%%\[ab\]a"
xchange *.tex "asd^13,^10" "%%asd ^13,^10"
xchange *.tex "abc f^10, d" "%%abc f d^10"
xchange *.tex "ad^10" "%%ad ^10"


xchange *.tex "\usepackage{color}" "\usepackage{color}\def\color#1{}" 

del *.aux;*.log;*.jpg;*.bmp

call delx -pk

for %a in (*.tex) call latex %a
for %a in (*.dvi) call dvi2img -bmpmono %a %@name[%a].bmp /r120

del *.aux;*.log