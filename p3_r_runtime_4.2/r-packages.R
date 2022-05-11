options(Ncpus = 12)
install.packages ("ggplot2", repos = "http://cran.wustl.edu")
install.packages ("svglite", repos = "http://cran.wustl.edu")
install.packages ("gridExtra", repos = "http://cran.wustl.edu")
install.packages ("reshape2", repos = "http://cran.wustl.edu")
install.packages ("BiocManager", repos = "http://cran.wustl.edu")
install.packages ("gridExtra", repos = "http://cran.wustl.edu")
install.packages ("svglite", repos = "http://cran.wustl.edu")

BiocManager::install(version = '3.15', ask = FALSE)
BiocManager::install(c( "DESeq2",
    "ComplexHeatmap",
    "EnhancedVolcano",
    "Biobase",
    "edgeR",
    "limma",
    "pcaMethods",
    "qvalue",
    "impute"));
