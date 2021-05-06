options(Ncpus = 12)
install.packages ("ggplot2", repos = "http://cran.wustl.edu", lib = "[% rlib %]")
install.packages ("svglite", repos = "http://cran.wustl.edu", lib = "[% rlib %]")
install.packages ("gridExtra", repos = "http://cran.wustl.edu", lib = "[% rlib %]")
install.packages ("reshape2", repos = "http://cran.wustl.edu", lib = "[% rlib %]")
install.packages ("BiocManager", repos = "http://cran.wustl.edu", lib = "[% rlib %]")

BiocManager::install()
BiocManager::install(c( "DESeq2",
    "ComplexHeatmap",
    "EnhancedVolcano",
    "Biobase",
    "edgeR",
    "limma",
    "pcaMethods",
    "qvalue",
    "impute"));
