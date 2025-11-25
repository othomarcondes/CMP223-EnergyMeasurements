	(use-modules (guix transformations)
		     (guix packages))

	(packages->manifest
	  (list (specification->package "stress")))
