function x = OrnsteinUhlenbeck(t,x0,tau,D)
% function x = OrnsteinUhlenbeck(t,x0,tau,D)
%
% Ornstein-Uhlenbeck process
% Integrated using forward Euler method
% 
% INPUTS
% t             time range (tStart:tStep:tEnd)
% x0            mean value 
% tau           time constant
% D             diffusion constant
%
% OUTPUTS
% x             random walk process

N = length(t); 
x = zeros(1,N);
dt = mean(diff(t));

for ii = 2:N
    
    x(ii) = x(ii-1) + dt*( -(x(ii-1)-x0)/tau + sqrt(D/dt)*randn(1) );
    
end
