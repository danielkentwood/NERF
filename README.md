# NERF
### Nonlinear Estimation of Receptive Fields

This is a repository for a project where I am attempting to estimate the spatiotemporal evolution of visual receptive fields in macaque prefrontal cortex neurons. I collected this data set with Mark Segraves at Northwestern University.

I use a Generalized Linear Model with Tikhonov Regularization. Estimating visual receptive fields using sparse sampling of the visual field (and accompanying neural responses) is an ill-posed problem. Tikhonov Regularization is a generalized form of L2 regularization that is ideal for inverse problems like this one. 

So far, the regularization doesn't appear to improve the results. 
