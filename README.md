# NERF
### Nonlinear Estimation of Receptive Fields

This is a repository for a project where I am attempting to estimate the spatiotemporal evolution of visual receptive fields in macaque prefrontal cortex neurons. I collected this data set with Mark Segraves at Northwestern University. This project is also in collaboration with Konrad Kording, Pavan Ramkumar (who colloborated on this code), Joshua Glaser, Patrick Lawlor, and Pedro Ribeiro.

Approach: We train a monkey to find a gabor patch embedded in perlin noise. We track its eye movements. While the monkey searches, we flash salient probes at random within the visual search space. We use the neural activity elicited by these probes to infer the visuospatial preferences (i.e., receptive fields) of the neurons we are recording from in prefrontal cortex. 

To analyze the data, I use a Generalized Linear Model with Tikhonov Regularization. Estimating visual receptive fields using sparse sampling of the visual field (and accompanying neural responses) is an ill-posed problem. Tikhonov Regularization, also known as Ridge Regression, is a generalized form of L2 regularization that is ideal for inverse problems like this one. 

So far, the Tikhonov regularization doesn't appear to improve the results. 
