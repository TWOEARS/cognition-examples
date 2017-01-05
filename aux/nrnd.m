
% this function generates an array of normally distributed random numbers
% it effectively replaces the normrnd function from the 'statistics toolbox'
% input:
%           mu: the mean of the random numbers
%           sigma the standard deviation of the random numbers
%           samples: the number of generated samples
function ret=nrnd(mu,sigma,samples)
    ret=sigma.*randn(1,samples) + mu;
end

