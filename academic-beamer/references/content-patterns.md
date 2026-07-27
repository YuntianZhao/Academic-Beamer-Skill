# Content Patterns

Use only patterns supported by the bundled `presentation.sty`. Replace example
content, labels, paths, and citation keys with verified presentation material.

## Title and Section Heading

```tex
\frame{\titlepage}

\begin{frame}
  \heading{Section title}
\end{frame}
```

## List

```tex
\begin{frame}
  \frametitle{Motivation}
  \begin{itemize}
    \item First verified point
    \item Second verified point
    \item Implication for the research question
  \end{itemize}
\end{frame}
```

## Two Columns

```tex
\begin{frame}
  \frametitle{Comparison}
  \begin{columns}[T,onlytextwidth]
    \begin{column}{0.47\textwidth}
      Left-side content.
    \end{column}
    \begin{column}{0.47\textwidth}
      Right-side content.
    \end{column}
  \end{columns}
\end{frame}
```

## Equation

```tex
\begin{frame}
  \frametitle{Estimating equation}
  \begin{equation*}
    Y_{it}=\alpha_i+\lambda_t+\beta D_{it}+X_{it}'\gamma+\varepsilon_{it}
  \end{equation*}
  State the estimand and identifying variation directly below the equation.
\end{frame}
```

## Figure and Note

```tex
\begin{frame}
  \frametitle{Main pattern}
  \begin{figure}
    \centering
    \includegraphics[max width=.96\textwidth,max height=.70\textheight]{figures/result.pdf}
    \caption{Descriptive caption}
    \figurenote{Source and sample definition.}
  \end{figure}
\end{frame}
```

Preserve aspect ratio. Prefer vector originals. Do not use a full paper page as
the figure.

## Table

```tex
\begin{frame}
  \frametitle{Main estimates}
  \begin{tabular*}{\textwidth}{@{\extracolsep\fill}lrr}
    \toprule
    Specification & Estimate & Standard error\\
    \midrule
    Baseline & 0.18 & 0.04\\
    Controls & 0.15 & 0.05\\
    \bottomrule
  \end{tabular*}
\end{frame}
```

Use `booktabs`, no vertical rules, and preserve reported units and precision.

## Theorem

```tex
\begin{frame}
  \frametitle{Main result}
  \begin{theorem}[Identification]
    Under the stated assumptions, the target parameter is point identified.
  \end{theorem}
  State why the assumptions are credible in the application.
\end{frame}
```

## Code

```tex
\begin{frame}[fragile]
  \frametitle{Estimation step}
\begin{lstlisting}[language=Python]
model.fit(data)
estimate = model.effect()
\end{lstlisting}
\end{frame}
```

For long external code, use `\lstinputlisting` in an `allowframebreaks` frame.

## References

When the deck cites sources, add `\addbibresource{references.bib}` in the
preamble and add verified entries to the bundled bibliography file.

```tex
\begin{frame}[allowframebreaks=0.8]
  \frametitle{References}
  \footnotesize
  \printbibliography[heading=none]
\end{frame}
```

## Closing and Backup Navigation

```tex
\begin{frame}[label=mainResult]
  \frametitle{Main result}
  Result summary.
  \hyperlink{robustness}{\beamergotobutton{Robustness details}}
\end{frame}

\lastslide

\begin{frame}[label=robustness]
  \frametitle{Robustness details}
  Supporting analysis.
  \hyperlink{mainResult}{\beamergotobutton{Return to main result}}
\end{frame}
```

## Local Density Escape Hatch

Use `\begin{singlespace} ... \end{singlespace}` only around the content of one
dense frame. Keep the deck-wide spacing unchanged. Prefer splitting unrelated
messages before reducing spacing.
