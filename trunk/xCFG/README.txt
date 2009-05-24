本目录是一个功能完整的中文TeX字体配置工具，基于最新版的FontsGen构建。将本目录置于TeX系统的localtexmf目录树下，执行

setup_winfonts.bat -slanted=y

即可。完成后视情况可能需要再执行mktexlsr、updmap等命令。参数-slanted=y的意义是对每个字体同时配置右斜体。将来的中文TeX可能会废止使用右斜体，因为它不符合中文排版规范，不过目前随主流中文宏包发行的fd文件中有右斜体配置，因此仍需要这些字体才能正常工作。

