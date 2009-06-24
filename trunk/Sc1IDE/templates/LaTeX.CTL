#TITLE=LaTeX
#INFO
LaTeX 
#SORT=n

#T=begin
\begin{}
^!
\end{}

#T=abstract
\begin{abstract}
^!
\end{abstract}

#T=tableofcontents
\tableofcontents

#T=section
\section{^! }

#T=subsection
\subsection{^! }

#T=appendix
\begin{appendix}
^!
\end{appendix}

#T=算法
\begin{alg}
^!
\end{alg}
#T=.例子
\begin{ex}
^!
\end{ex}
#T=.定理
\begin{thm} \label{}
^!
\end{thm}
#T=.引理
\begin{lem} \label{}
^!
\end{lem}
#T=.命题
\begin{prop} \label{}
^!
\end{prop}
#T=.定义
\begin{defn}
^!
\end{defn}
#T=.推论
\begin{cor} \label{}
^!
\end{cor}
#T=.注记
\begin{rem} \label{}
^!
\end{rem}
#T=.条件
\begin{cond} \label{}
^!
\end{cond}
#T=参考文献(bibtex)
\bibliography{^!}
\bibliographystyle{plain}
#T=参考文献
\begin{thebibliography}{99}
  \bibitem{^! }
\end{thebibliography}
#T=eqa[1]/eqn[]/eqm[1,2,3]/eqz[$]
\eqa{\label{}
^!
}
#T=label
\label{^!}
#T=ref
\ref{^!}
#T=center
\begin{center}
^!
\end{center}
#T=description
\begin{description}
\item[] ^!
\end{description}
#T=displaymath
\begin{displaymath}
^!
\end{displaymath}
#T=document
\begin{document}
^!
\end{document}
#T=itemize
\begin{itemize}
\item ^!
\end{itemize}
#T=enumerate
\begin{enumerate}
\item ^!
\end{enumerate}
#T=lstlistings
\lstset{language=C}
\begin{lstlisting}{}
^!
\end{lstlisting}
#T=environment
\begin{environment}{^!} \end{environment}
#T=frac
\frac{^!}{^!}
#T=equation
\begin{equation}\label{}
^!
\end{equation}
#T=array
\begin{array}{lll}
^!
\end{array}
#T=eqarray
\begin{equation}\label{} \begin{array}{lll}
^!
\end{array} \end{equation}
#T=eqnarray
\begin{eqnarray}
^!
\end{eqnarray}
#T=eqnarray*
\begin{eqnarray*}
^! 
\end{eqnarray*}
#T=align
\begin{align} 
^!
\end{align}
#T=align*
\begin{align*}
^!
\end{align*}
#T=alignat
\begin{alignat}{2}
^!
\end{alignat}
#T=subequations
\begin{subequations}
^!
\end{subequations}
#T=aligned
\begin{aligned}
^!
\end{aligned}
#T=split
\begin{split}
^!
\end{split}
#T=matrix
\begin{matrix}
^!
\end{matrix}
#T=pmatrix
\begin{pmatrix}
^!
\end{pmatrix}
#T=smallmatrix
\begin{smallmatrix}
^!
\end{smallmatrix}
#T=cases
\begin{cases}
^!
\end{cases}
#T=gather
\begin{gather}
^!
\end{gather}
#T=gather*
\begin{gather*}
^!
\end{gather*}
#T=multline
\begin{multline}
^!
\end{multline}
#T=multline*
\begin{multline*} 
^!
\end{multline*}
#T=setlength
\begin{setlength}
^!
\end{setlength}

#T=figure
\begin{figure}[!htbp] %Default value is [tbp]
%h:here, t:top, b:bottom, p:page !: no restrictions for spacing and number
^!
\end{figure}
#T=figure*
\begin{figure*}[!tp] %t: top, p:page !:no restrictions for spacing and number
^!
\end{figure*}
#T=filecontents
\begin{filecontents}{^!} %Only be given before \documentclass

\end{filecontents}
#T=filecontents*
\begin{filecontents*}{^!} %Only be given before \documentclass

\end{filecontents*}

#T=flushleft
\begin{flushleft}
^! \\
\end{flushleft}
#T=fussypar
\begin{fussypar}
^!
\end{fussypar}
#T=flushright
\begin{flushright}
^! \\
\end{flushright}
#T=letter
\begin{letter}{ \\}
^!
\end{letter}
#T=list
\begin{list}{ }{ }
\item ^!
\end{list}
#T=lrbox
\begin{lrbox}{\ }
 ^! 
\end{lrbox}
#T=macro
\begin{macro}{\aa} ^! \end{macro}
#T=math
\begin{math}
^!
\end{math}
#T=minipage
\begin{minipage}{8cm} %Given the width of this environment
^!
\end{minipage}
#T=note
\begin{note}
^!
\end{note}
#T=overlay
\begin{overlay}
^!
\end{overlay}
#T=picture
\begin{picture}(300 , 200)
\put(0,0){\special{BMF=^!.bmf}}
\end{picture}
#T=quotation
\begin{quotation}
^!
\end{quotation}
#T=quote
\begin{quote}
^!
\end{quote}
#T=rotate
\begin{rotate}{^!}  \end{rotate}
#T=samepage
\begin{samepage}
^!
\end{samepage}
#T=sideways
\begin{sideways} ^! \end{sideways}
#T=slide
\begin{slide}
^!
\end{slide}
#T=sloppypar
\begin{sloppypar}
^!
\end{sloppypar}
#T=tabbing
\begin{tabbing}
^!
\end{tabbing}
#T=table
\begin{table}[!htbp] %Default value is [tbp]
%h:here, t:top, b:bottom, p:page !: no restrictions for spacing and number
^!
\end{table}
#T=table*
\begin{table*}[!tp] %t: top, p:page !:no restrictions for spacing and number
^!
\end{table*}
#T=tabular
\begin{tabular}{||c|c|c||}
^!
\end{tabular}
#T=tabular*
\begin{tabular*}{}
^!
\end{tabular*}
#T=theindex
\begin{theindex}
\item ^!
\end{theindex}
#T=titlepage
\begin{titlepage}
^!
\end{titlepage}
#T=trivlist
\begin{trivlist}
^!
\end{trivlist}
#T=turn
\begin{turn} ^! \end{turn}
#T=verbatim
\begin{verbatim}
^!
\end{verbatim}
#T=verbatim*
\begin{verbatim*}
^!
\end{verbatim*}
#T=verse
\begin{verse}
^! \\
\end{verse}
#T=\left
\left^!\right.
#T=\setlength
\setlength{\^!}{}
#T=\acute
\acute{^!}
#T=\addcontentsline
\addcontentsline{^!}{}{}
#T=\address
\address{^!}
#T=\addtime
\addtime{^!}
#T=\addtocontents
\addtocontents{^!}{}
#T=\addtocounter
\addtocounter{^!}{}
#T=\addtolength
\addtolength{\^!}{}
#T=\addvspace
\addvspace{^!}
#T=\Alph
\Alph{^!}
#T=\alph
\alph{^!}
#T=\arabic
\arabic{^!}
#T=\AtBeginDocument
\AtBeginDocument{^!}
#T=def
\def \AA#1 {^!}

#T=newfont
\newfont {\AA} {}

#T=newcommand
\newcommand{\AA}[2] {#1^2+#2^2}

#T=--picture--
\begin{picture}(100,60)
\put(0,0){^!}
\end{picture}
#T=\put
\put(0,0){^!}
#T=\multiput
\multiput(0,0)(+5,0){3}{^!}
#T=\shortstack
\shortstack{^!}
#T=\frame
\frame{^!}
#T=\framebox
\framebox(10,5){^!}
#T=\dashbox
\dashbox(10,5){^!}
#T=\makebox
\makebox(10,5){^!}
#T=\parbox
\parbox(10,5){^!}
#T=\savebox
\newsavebox{\pic1}
\savebox{\pic1}(10,5){^!}
#T=\usebox
\usebox{\pic1}
#T=\line
\line(+1,0){^!}
#T=\vector
\vector(+1,0){^!}
#T=\qbezier
\qbezier(^!,^!)(^!,^!)(^!,^!)
#T=\emline
\emline{^!}{^!}{1}{^!}{^!}{1}
#T=\circle
\circle{^!}
#T=\oval
\oval(^!,^!)
#T=\thicklines
\thicklines
#T=\thinlines
\thinlines
#T=\linethickness
\linethickness{1mm}

#