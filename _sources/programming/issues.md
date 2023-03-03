# Issues and solutions
## Read -1, expected \<number\>, errno =1
在docker容器中，MPI多核执行GPU程序，可能会报该错误。

`````{admonition} Solution
:class: tip
设置环境变量解决: [**Reference**](https://github.com/open-mpi/ompi/issues/4948)

`export OMPI_MCA_btl_vader_single_copy_mechanism=none`
`````
