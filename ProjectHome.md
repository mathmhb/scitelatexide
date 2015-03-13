
---


# **项目说明** #

从开发MiCTeX套装的早期开始，我一直在努力对SciTE编辑器进行修改、配置，以使它成为一个方便易用的latex编辑环境。在这个过程中我新建、修改了若干与latex有关的lexer（包括latex/metapost/bibtex/asymptote的lexer）、对增加了一些新功能（如用户可自行设置的工具条、各种增强SciTE功能的lua脚本等），同时从数量庞大的其他来源借用了不少新技术（包括latex-gui/SciTE-Ru等项目）。此外我还写了几个perl脚本并转换成Windows执行文件，用来帮助用户自动完成latex等格式的自动排版以及自动为tex系统配置中文字体等。最终的捆绑结果就是现在的SciTE LaTeX IDE。我希望有一天它将成长为一个真正意义上的IDE环境。

# **Introduction** #

Since the early days when my Chinese TeX Suite MiCTeX was being developed, I have been paying my efforts in modifying and configuring SciTE editor in order to make latex editing more comfortable. In this process I created/modified several latex related lexers (latex/metapost/bibtex/asymptote) and added new functions to the editor (user customizable toolbars, various lua scripts which makes the editor much more like a latex IDE, etc) and also borrowed advanced techniques from diverse sources (latex-gui/SciTE-Ru project etc). Moreover, I also wrote some perl scripts for automatic latex compilation and preview, and compiled them into Windows executables. The final boundle is here: LaTeX IDE. I hope one day it will get to the point as a real IDE for latex editing.


---


# **依赖关系** #

SciTE LaTeX IDE是基于SciTE、SciTE-Ru及scite-gui库的导出项目。

  * SciTE是Neil Hodgson开发的优秀的编辑器，主页在http://www.scintilla.org/。

  * SciTE-Ru是一个俄罗斯用户组维护的对SciTE的改进扩充版，主页在http://code.google.com/p/scite-ru/。

  * scite-gui是第三方用户Steve D开发的gui库，可以在http://mysite.mweb.co.za/residents/sdonovan/SciTE/gui_ext.zip获得源码和编译好的二进制动态库。本项目未纳入scite-gui的源码，因为我从未正确地编译它。但项目包含了gui.dll这个库，因为相当一部分Lua脚本要依赖它。

# **Dependences** #
SciTE LaTeX IDE is a derived project which depends on SciTE, SciTE-Ru and scite-gui library.

  * SciTE is an execellent text editor and text editing component written by Neil Hodgson. Its home page can be found at http://www.scintilla.org/.

  * SciTE-Ru is an extended version of SciTE developed by a group of Russian users which can be found at http://code.google.com/p/scite-ru/.

  * scite-gui is a GUI library developed by Steve D which can be found at http://mysite.mweb.co.za/residents/sdonovan/SciTE/gui_ext.zip. The present project does not include the source of scite-gui, because I have never been able to compile scite-gui myself, however I included its compiled binary library gui.dll, since a considerable amount of Lua scripts in this project depends on gui.dll.


---


# **编译方法** #

SciTE LaTeX IDE 是一个Windows应用项目。虽然为保持代码的完整性， 在源代码中包含了GTK和OSX的目录树，但是因为scite-gui只能在Windows下使用，因此无法确保SciTE LaTeX IDE的功能在其他平台下能完整体现。我个人使用的编译器是Mingw，但MSVC应该也可以使用。编译时依次进入scintilla\win32和scite\win32目录执行mingw-make即可。另外，iconlib目录下的make.bat也需要单独执行，以获得自定制的工具栏图标库。最后，将编译所得的SciTE.exe和toolbar.dll放入svn原码中的Release目录即可使用 (Revison35)。

# **Method for Compilation** #

SciTE LaTeX IDE is a Windows project. Although for completeness the souce code contains GTK and OSX trees, SciTE LaTeX IDE can only be made fully  functional under Windows, because the crucial component scite-gui can only work under Windows. Personally I use the MingW compiler for compiling SciTE LaTeX IDE, however MSVC should also work. For compilation, go to the directories  scintilla\win32 and cite\win32 respectively and execute mingw-make. You should also execute make.bat under iconlib tree in order to obtain the user toolbar library. Finally, put SciTE.exe and toolbar.dll into the Release tree of svn source to get a ready-to-use version of SciTE LaTeX IDE ([Revision35](https://code.google.com/p/scitelatexide/source/detail?r=35)).


---


# **屏幕截图 （Screenshots）** #

  * TeX
![http://scitelatexide.googlecode.com/files/LaTeXIDE-TeX.png](http://scitelatexide.googlecode.com/files/LaTeXIDE-TeX.png)

  * Asymptote
![http://scitelatexide.googlecode.com/files/LaTeXIDE-Asy.png](http://scitelatexide.googlecode.com/files/LaTeXIDE-Asy.png)


---


# **参与开发** #

如果你对C++编程或者lua脚本语言或者SciTE配置脚本（properties文件）有经验并且有兴趣参与改进这个编辑器，欢迎加入开发。

# **Join Development** #

If you are experienced with C++ or lua programming or are familiar with SciTE's properties files and wish to contribute your ideas, we welcome you to join the development of this special variant of SciTE.

<a href='Hidden comment: 
Enter your comments here:
'></a>