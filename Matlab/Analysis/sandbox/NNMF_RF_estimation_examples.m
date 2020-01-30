% XCORR (Patrick Mineault) examples for RF estimation during remapping

%% Create RF

clf
% Create a "remapped receptive field"
[xi,yi] = meshgrid(-10:10,-20:20);
% early visual component
c1 = exp((-((xi+5).^2/2+(yi+8).^2/32)/2));
% late remapped attentional component
c2 = exp((-((xi-5).^2/2+(yi-8).^2/32)/2));
rf = c1+c2;
imagesc(xi(:),yi(:),rf,[-1,1]);
xlabel('position');
ylabel('time');
axis xy
axis equal;
axis tight

%% SVD

clf
[U,S,V] = svd(rf);
subplot(2,3,1);plot(U(:,1)*sign(mean(U(:,1))));title('first temporal component');
subplot(2,3,2);plot(V(:,1)*sign(mean(U(:,1))));title('first spatial component');
subplot(2,3,3);imagesc(S(1,1)*U(:,1)*V(:,1)',.7*[-1,1]);title('first spatial-temporal component');
subplot(2,3,4);plot(U(:,2)*sign(mean(U(:,2))));title('second temporal component');
subplot(2,3,5);plot(V(:,2)*sign(mean(U(:,2))));title('second spatial component');
subplot(2,3,6);imagesc(S(2,2)*U(:,2)*V(:,2)',.7*[-1,1]);title('second spatial-temporal component');

%% Non-negative matrix factorization (NNMF)

[U,V] = nnmf(rf,2);
V = V';
subplot(2,3,1);plot(U(:,1)*sign(mean(U(:,1))));title('first temporal component');
subplot(2,3,2);plot(V(:,1)*sign(mean(U(:,1))));title('first spatial component');
subplot(2,3,3);imagesc(U(:,1)*V(:,1)',[-1,1]);title('first spatial-temporal component');
subplot(2,3,4);plot(U(:,2)*sign(mean(U(:,2))));title('second temporal component');
subplot(2,3,5);plot(V(:,2)*sign(mean(U(:,2))));title('second spatial component');
subplot(2,3,6);imagesc(U(:,2)*V(:,2)',[-1,1]);title('second spatial-temporal component');


%% Add noise to the RF

rf = c1+c2+randn(size(c1))*.2;
clf
imagesc(xi(:),yi(:),rf,[-1,1]);
xlabel('position');
ylabel('time');
axis xy
axis equal
axis tight


%% Noise + SVD

[U,S,V] = svd(rf);
subplot(2,3,1);plot(U(:,1)*sign(mean(U(:,1))));title('first temporal component');
subplot(2,3,2);plot(V(:,1)*sign(mean(U(:,1))));title('first spatial component');
subplot(2,3,3);imagesc(S(1,1)*U(:,1)*V(:,1)',.7*[-1,1]);title('first spatial-temporal component');
subplot(2,3,4);plot(U(:,2)*sign(mean(U(:,2))));title('second temporal component');
subplot(2,3,5);plot(V(:,2)*sign(mean(U(:,2))));title('second spatial component');
subplot(2,3,6);imagesc(S(2,2)*U(:,2)*V(:,2)',.7*[-1,1]);title('second spatial-temporal component');


%% Noise + NNMF

[U,V] = nnmf(rf,2,'replicates',5);
V = V';
subplot(2,3,1);plot(U(:,1)*sign(mean(U(:,1))));title('first temporal component');
subplot(2,3,2);plot(V(:,1)*sign(mean(U(:,1))));title('first spatial component');
subplot(2,3,3);imagesc(U(:,1)*V(:,1)',[-1,1]);title('first spatial-temporal component');
subplot(2,3,4);plot(U(:,2)*sign(mean(U(:,2))));title('second temporal component');
subplot(2,3,5);plot(V(:,2)*sign(mean(U(:,2))));title('second spatial component');
subplot(2,3,6);imagesc(U(:,2)*V(:,2)',[-1,1]);title('second spatial-temporal component');


%% ALD

niter = 3;
ncomps = size(V,2);
% Start with U,V from NNMF
sserror = zeros(niter,1);
for ii = 1:niter
    for kk = 1:ncomps
        res = rf - U*V' + U(:,kk)*V(:,kk)';
        
        Xmat = [];
        for nn = 1:size(V,1)
            Xmat = blkdiag(Xmat,U(:,kk));
        end
        %reestimate spatial filters
        y = res(:);
        results = runALD(Xmat,y,size(V,1),1);
        V(:,kk) = results.khatSF;
        
        Xmat = [];
        for nn = 1:size(U,1)
            Xmat = blkdiag(Xmat,V(:,kk));
        end
        %reestimate spatial filters
        y = res';
        y = y(:);
        results = runALD(Xmat,y,size(U,1),1);
        U(:,kk) = results.khatSF;
    end
    yp = U*V';
    sserror(ii) = .5*sum((rf(:)-yp(:)).^2);
end
subplot(2,3,1);plot(U(:,1)*sign(mean(U(:,1))));title('first temporal component');
subplot(2,3,2);plot(V(:,1)*sign(mean(U(:,1))));title('first spatial component');
subplot(2,3,3);imagesc(U(:,1)*V(:,1)',[-1,1]);title('first spatial-temporal component');
subplot(2,3,4);plot(U(:,2)*sign(mean(U(:,2))));title('second temporal component');
subplot(2,3,5);plot(V(:,2)*sign(mean(U(:,2))));title('second spatial component');
subplot(2,3,6);imagesc(U(:,2)*V(:,2)',[-1,1]);title('second spatial-temporal component');
