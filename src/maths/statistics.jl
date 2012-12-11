module Statistics


import Distributions
using Distributions

import Base.mean, Base.inv, Base.std

export inv,mean, kurtosis, skewness

mean(v::AbstractVector, w::AbstractVector) = weighted_mean(v,w)
var(v::AbstractVector, w::AbstractVector) = var(v, mean(v,w), true) 
std(v::AbstractVector, w::AbstractVector) = sqrt(var(v, w))

skewness(v::AbstractVector, w::AbstractVector) = skewness(v, mean(v,w), true)
kurtosis(v::AbstractVector, w::AbstractVector) = kurtosis(v, mean(v,w), true)

gaussian_downside_variance(v::AbstractVector, w::AbstractVector) = guassian_regret(v,w,0)
gassian_downside_deviation(v::AbstractVector, w::AbstractVector) = sqrt(gaussian_downside_variance(v,w))

#Dembo, Freeman "The Rules Of Risk", Wiley (2001)
function guassian_regret(v::AbstractVector, w::AbstractVector, target::Real)
	m=mean(v,w)
	s = std(v, w)
	variance = var(v, w)
	f1 = variance + m*m -2*target*m + target*target
	d=Normal(m, s)
	alpha = cdf(d, target)
	f2 = m-target
	beta = variance*pdf(d, target)
	(alpha*f1 - beta*f2) / alpha
end

function guassian_percentile(v::AbstractVector, w::AbstractVector, percentile::Real)
	@assert percentile > 0
	@assert percentile < 1.0
	m=mean(v,w)
	s=std(v,m,true)
	quantile(Normal(m,s), percentile)
end

function gaussian_top_percentile(v::AbstractVector, w::AbstractVector, percentile::Real)
	guassian_percentile(v,w,percentile)
end

function gaussian_potential_upside(v::AbstractVector, w::AbstractVector, percentile::Real)
	@assert percentile <1.0 && percentile >= 0.9
	max(guassian_percentile(v,w,percentile),0.0)
end

function gaussian_value_at_risk(v::AbstractVector, w::AbstractVector, percentile::Real)
	@assert percentile <1.0 && percentile >= 0.9
	-1*min(guassian_percentile(v,w,1-percentile),0.0)
end

#Artzner, Delbaen, Eber and Heath, "Coherent measures of risk", Mathematical Finance 9 (1999)
function gaussian_expected_shortfall(v::AbstractVector, w::AbstractVector, percentile::Real)
	@assert percentile <1.0 && percentile >= 0.9
	m=mean(v,w)
	s=std(v,m,true)
	d=Normal(m,s)
	var = quantile(1-percentile)
	g=pdf(d, var)
	r=m-s*s*g/(1-percentile)
	return -1*min(r,0)
end

function gaussian_shortfall(v::AbstractVector, w::AbstractVector, target::Real) 
	m=mean(v,w)
	s=std(v,m,true)
	cdf(Normal(m,s), target)
end

function gaussian_average_shortfall(v::AbstractVector, w::AbstractVector, target::Real)
	m=mean(v,w)
	s=std(v,m,true)
	d=Normal(m,s)
	g=pdf(d,target)
	gi=cdf(d, target)

	(target - m) + s*s*g/gi
end

error_estimate(v::AbstractVector, w::AbstractVector) = sqrt(var(v,w))

function skewness(v::AbstractVector, m, corrected::Bool)
	n=numel(v)
	vv=v-m
	y=sum((vv.*vv).*vv) / n
	sigma = std(v,false)
	if corrected
		@assert n>2
		(y/(sigma*sigma*sigma)) * (sqrt(n*(n-1))/(n-2))
	else 
		(y/(sigma*sigma*sigma)) 
	end
end

function kurtosis(v::AbstractVector, m, corrected::Bool)
	n=numel(v)
	vv=v-m
	x=sum (((vv.*vv).*vv).*vv) / n
	sigma = std(v,false)
	k=x/(sigma*sigma*sigma*sigma)
	if corrected
		@assert n>3
		((n-1)/((n-2)*(n-3)) ) * (((n+1)*k) - 3*(n+1) )  
	else 
		k - 3
	end
end


end