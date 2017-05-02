function [ B, H, w ] = drsvm( Y, X, k, lambda1, lambda2, maxiter, Ytest )
%DRSVM Summary of this function goes here
%   min sum l(h_i, w) + lambda1/2 \|w\|_2^2 + lambda2/2 \|X - BH\|_F^2 +
%   lambda3 \|B\|_F^2 + lambda4 \|H\|_F^2
[m, n] = size(X);
B = randn(m, k);
H = randn(k, n);
w = randn(k, 1);
ntr = size(Y, 1);
%XTX = X'*X;
trXTX = norm(X, 'fro')^2;
clearvars XTX;
obj(Y, X, B, H, w, lambda1, lambda2, trXTX)
sgd_t = 1;
for iter = 1:maxiter
    fprintf('%d iteration.\n', iter);
    %Update B    
    tic;
    %HHT = H*H';
    %XHT = X*H';
    %for i = 1:k,
    %    B(:,i) = B(:,i) + ( XHT(:,i) - B*HHT(:,i) ) / H(i,i);
    %end
    HHT = H*H';
    HXT = H*X';
    BT = HHT \ HXT;
    B = BT';
    %toc
    disp('Update B')
    toc
    obj(Y, X, B, H, w, lambda1, lambda2, trXTX)

    %Update Htest
    %BTB = B'*B;
    %BTXtest = B'*X(:,(ntr+1):n);
    %Htest = BTB \ BTXtest;
    %H(:,(ntr+1):n) = Htest;
    %obj(Y, X, B, H, w, lambda1, lambda2, trXTX)
    
    %Update Htrain
    tic;
    BTB = B'*B;
    disp('BTB');
    
    XtrTB = X(:,1:ntr)'*B;
    XteTB = X(:,ntr+1:n)'*B;
    toc
    for i = 1:k,
   %    disp('frist');
   %    tic
       %bjnorm = norm(B(:,i), 'fro')^2;
       bjnorm = BTB(i,i);
       %tic;
       sol1 = H(i,1:ntr)' + ( XtrTB(:,i) - H(:,1:ntr)'*(BTB(:,i))  ) / bjnorm;
       sol2 =  H(i,1:ntr)' + ( XtrTB(:,i) - H(:,1:ntr)'*(BTB(:,i))  ) / bjnorm  + w(i,1)*Y/(lambda2*bjnorm);
       %disp('calculating sol');
       
       
       H(i,ntr+1:n) = H(i,ntr+1:n) + (XteTB(:,i)' - BTB(:,i)'*H(:,ntr+1:n) ) / bjnorm; 
       
       
       idx = [1:k];
       idx(i) = [];
       thresold = (1 - Y.*(H(idx,1:ntr)' * w(idx,:) )) ./ (Y*w(i, 1));
       %toc
       %    toc
    %   disp('second')
    %   tic
       sol = sol1;
       pos_deno = Y*w(i,1) > 0;
       neg_deno = Y*w(i,1) < 0;
       zero_deno = Y*w(i,1) == 0;
       if sum(zero_deno) > 0,
          error('error: zero denominator') 
       end
       %size(sol1)
       %ii = sol1 >= thresold;
       pos1 = ( pos_deno & (sol1 >= thresold) ) | (neg_deno & (sol1 <= thresold));
       pos2 = ( pos_deno & (sol2 < thresold) ) | (neg_deno & (sol2 > thresold));
       if( sum(pos1 & pos2) ~= 0 ),
          error('error: pos1 & pos2 in not empty') 
       end
       pos3 = ~(pos1) & ~(pos2);
       sol(pos1) = sol1(pos1);
       sol(pos2) = sol2(pos2);
       sol(pos3) = thresold(pos3);
       
      % toc
       H(i,1:ntr) = sol;
       %fprintf('i = %d \n', i);       
    end
    
    disp('Update Htr');
    toc
    obj(Y, X, B, H, w, lambda1, lambda2, trXTX)


    %Update w  Pegasos algorithm
    tic
    %size(Y)
    %size(H(:,1:ntr)')
    par = ['-c ' num2str(1/lambda1) ' -s 3' ];
    model = train(Y, sparse(H(:,1:ntr)'), par);
    w = model.w';
    %size(w)
%     T = 1*ntr;
%     for t = 1:T,
%         ti = randi(ntr);
%         eta = 1/(sgd_t*lambda1+1e1);
%         if Y(ti,1)*(w'*H(:,ti)) < 1,
%             w = (1 - eta*lambda1) * w  + eta*Y(ti,1)*H(:,ti); 
%         else
%             w = (1 - eta*lambda1) * w;
%         end
%         sgd_t = sgd_t + 1;
%     end
  
    
%     eta = 1e-1;
%     for i = 1:n,
%         subgrad = ( Y(i)*w'*H(:,i) <= 1 )*(-Y(i)*H(:,i)) + lambda1*w;
%         w = w - eta*subgrad;
%     end
    disp('Update w')
    toc
    obj(Y, X, B, H, w, lambda1, lambda2, trXTX)
    
    acc_tr = pred(Y, H(:,1:ntr), w);
    fprintf('training pred accuracy: %d\n', acc_tr)
    acc_te = pred(Ytest, H(:,ntr+1:n), w);
    fprintf('testing pred accuracy: %d\n', acc_te)
end


end

