function M = g2_mts_direction(KI, KII)
%G2_MTS_DIRECTION  Signed tensile maximum-tangential-stress kink angle (WP3_PREREGISTRATION.md s.1).
%
%  M = g2_mts_direction(KI, KII)
% Frame: t = growth direction, n = R(+90 deg) t, upper face theta = +pi on the
% +n side, KII > 0 = upper face slides in +t relative to the lower face.
% Continuous tensile root of KI sin(th) + KII (3 cos(th) - 1) = 0:
%   th = 2 atan2(-2 KII, KI + sqrt(KI^2 + 8 KII^2))     (no cancellation for small KII)
% New tangent: t1 = cos(th) t + sin(th) n  (th < 0 turns towards -n).
%
% Fail-closed regimes (M.status); only status 'OK' is admissible for a step:
%   HOLD_NONFINITE_K, HOLD_ZERO_K, HOLD_NEGATIVE_KI_CONTACT_OR_COMPRESSION -> theta empty
%   DOCUMENTED_PURE_MODE_II (KI == 0, KII ~= 0) -> theta returned, not admissible
%   HOLD_NONTENSILE_OR_NOT_MAXIMUM if the hoop stress at the root is not a positive maximum
% Pure algebra: no mesh, no FEM, no toughness, no onset statement.
M=struct('status','','admissibleForStep',false,'theta_rad',[],'theta_deg',[], ...
 'KI',KI,'KII',KII,'stationarityResidual_rel',[],'hoop',[],'hoopSecondDerivative',[], ...
 'physicalOnset',false);
if ~(isnumeric(KI)&&isnumeric(KII)&&isscalar(KI)&&isscalar(KII)&&isreal(KI)&&isreal(KII))
 error('G2MTS:Input','KI and KII must be real numeric scalars.');
end
if ~isfinite(KI)||~isfinite(KII),M.status='HOLD_NONFINITE_K';return,end
if KI==0&&KII==0,M.status='HOLD_ZERO_K';return,end
if KI<0,M.status='HOLD_NEGATIVE_KI_CONTACT_OR_COMPRESSION';return,end
th=2*atan2(-2*KII,KI+hypot(KI,sqrt(8)*KII));
M.theta_rad=th;M.theta_deg=th*180/pi;
M.stationarityResidual_rel=abs(KI*sin(th)+KII*(3*cos(th)-1))/hypot(KI,KII);
f=@(x)cos(x/2).*(KI*cos(x/2).^2-1.5*KII*sin(x));   % hoop stress times sqrt(2*pi*r)
M.hoop=f(th);
% analytic second derivative of f at the root
c=cos(th/2);s=sin(th/2);
M.hoopSecondDerivative=-.25*c*(KI*c^2-1.5*KII*sin(th)) ...
 +s*(KI*c*s+1.5*KII*cos(th)) ...
 +c*(.5*KI*(s^2-c^2)+1.5*KII*sin(th));
if KI==0
 M.status='DOCUMENTED_PURE_MODE_II';return
end
if ~(M.hoop>0&&M.hoopSecondDerivative<0)
 M.status='HOLD_NONTENSILE_OR_NOT_MAXIMUM';M.theta_rad=[];M.theta_deg=[];return
end
M.status='OK';M.admissibleForStep=true;
end
