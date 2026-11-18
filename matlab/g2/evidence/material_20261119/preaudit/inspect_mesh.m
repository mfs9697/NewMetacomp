function inspect_mesh(f)
S=load(f);fn=fieldnames(S);disp(fn.');
D=S.(fn{1});if isstruct(D)&&numel(fn)==1,else,D=S;end
disp(fieldnames(D).');
X=D.X6;T=D.T6;fprintf('X6 %d nodes, T6 %d elements\n',size(X,1),size(T,1));
c=[152.4 69.85;152.4 120.65;152.4 171.45];
for k=1:3
 r=vecnorm(X-c(k,:),2,2);
 d=abs(r-19.05);on=d<1e-6;
 fprintf('hole %d: nodes |r-19.05|<1e-6: %d (maxdev %.3g); next nearest %.4g mm\n',k,nnz(on),max(d(on)),min(d(~on)));
 v=unique(T(:,1:3));rv=r(v);dv=abs(rv-19.05);onv=dv<1e-6;
 fprintf('  T3 vertices on circle %d (maxdev %.3g), next %.4g; T6 midside on circle %d\n',nnz(onv),max(dv(onv)),min(dv(~onv)),nnz(on)-nnz(onv));
 dh=abs(r-6.35);oh=dh<1e-6;fprintf('  hole-rim nodes %d maxdev %.3g, min r %.6g\n',nnz(oh),max(dh(oh)),min(r));
end
disp(D.crackPolyline);
fprintf('tip guide? fields with guide: %s\n',strjoin(fn(contains(fn,'uide')),','));
