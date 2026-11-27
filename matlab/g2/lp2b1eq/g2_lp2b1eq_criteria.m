function c=g2_lp2b1eq_criteria(m,tol)
%G2_LP2B1EQ_CRITERIA  C1-C11 of the LP2-B1-EQ comparison from the metrics alone (pure; no I/O).
% Identical inequalities and thresholds to the accepted WP5 comparator (g2_lp2a2_eq_compare): every bound is
% inclusive (<=), so a metric exactly at its tolerance passes. Changes: C10 is the state-specific next-tip
% displacement (same 5e-4 mm); C9 adds the stronger subgate "archived active area exactly 0 -> new exactly 0"
% when tol.activeAreaExactZeroWhenArchivedZero is true.
c=struct();
c.C1_KI=abs(m.dKI_overKeq)<=tol.KI_overKeq;
c.C2_KII=abs(m.dKII_overKeq)<=tol.KII_overKeq;
c.C3_KIIoverKI=abs(m.dKIIoverKI)<=tol.KIIoverKI_abs;
c.C4_G_J=abs(m.dG_rel)<=tol.G_rel&&abs(m.dJ_rel)<=tol.J_rel&&abs(m.newJoverGminus1)<=tol.newJoverGminus1;
c.C5_MTS=abs(m.dMTS_deg)<=tol.MTS_deg&&m.newMTSadmissible;
c.C6_COD_EDI=m.newCODminusEDI_rel<=tol.newCODminusEDI_gate&&abs(m.dCODminusEDI)<=tol.dCODminusEDI;
c.C7_EDI_spread_quadrature=m.newPathSpread_rel<=max(tol.spreadFloor,tol.spreadFactor*m.archivedPathSpread_rel)&& ...
 m.newQuad4x4_rel<=max(tol.quadFloor,tol.quadFactor*m.archivedQuad4x4_rel);
c.C8_crackOpening=m.openingNearTipRel<=tol.openingNearTipRel&&m.openingWholeCrackRel<=tol.openingWholeCrackRel;
zeroOK=~tol.activeAreaExactZeroWhenArchivedZero||m.archivedActiveArea_mm2~=0||m.newActiveArea_mm2==0;
c.C9_phaseActivation=m.newSolverGatesPass&&m.chordsEqual&&abs(m.dActiveArea_rel)<=tol.activeArea_rel&&zeroOK;
c.C10_nextPredictor=m.nextTipDisplacement_mm<=tol.nextTipDisplacement_mm;
c.C11_compliance=abs(m.dCompliance_rel)<=tol.compliance_rel;
end
