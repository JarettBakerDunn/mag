      subroutine cmbcoeff(kc)
c
c  called in amhd
c  supplied by urc
c  modified by polson and wmi
c
c  output of complex spherical harmonic coefficients
c  for the poloidal magnetic potential b at the outer
c  boundary and of the poloidal velocity potential w,
c  its radial derivative dw, and the toroidal velocity
c  potential z at the radial level kc
c
      include 'param.f'
      include 'com1.f'
      include 'com3.f'
      include 'com4.f'
      include 'com5.f'
      include 'com8.f'
      
      dimension la(nlma),ma(nlma)
      dimension alm(lmax,lmax),blm(lmax,lmax)
      dimension glm(lmax,lmax),hlm(lmax,lmax)
c
c   constants
c
      pi=4.*atan(1.)
      pi4inv=1./(4.*pi)
      anano=1.0e+09

c
c   nominal Earth parameters
c
      sigma=6.0e+05     ! Core electrical conductivity in S/m
      rho=11.e+03       ! Core mean density in kg m^{-3}
      omega=7.2924e-05  ! Rotation angular frequency
      escale=sqrt(rho*omega/sigma)  ! "Elsasser number" scaling
      re=6.371e+06      ! Earth radius in m
      rc=3.485e+06      ! Core radius in m
      ri=1.215e+06      ! Inner core radius in m
      cdepth=rc-ri      ! Depth of outer core
      rcre=rc/re        ! core/surface radius ratio
      rcsqinv=(cdepth/rc)**2  ! dim-less inverse squared core radius
c
c   harmonic factors
c
      fl=float(l)
      flp2=fl + 2.
      fl2p1=(2.*fl) + 1.
      fm=float(m)
      fact=sqrt(fl2p1*pi4inv)
      fact1=((-1.)**fm)*fl*fact
       if(m.gt.0) fact1=fact1*sqrt(2.)
      fact2=rcsqinv*(rcre**flp2)

c
c   define MAG harmonic-Gauss harmonic conversion factors
c   conalm,conblm
c
      conalm=fact1
      conblm=-fact1
      
c
c  write header
c
      write(21,2100) nlma,lmax,minc,r(1),r(kc),time/tscale
 2100 format(/, 2x,"nlma=",i3,2x,"lmax=",i3,2x,"minc=",i3,2x,
     $   "r(1)=",f7.4,2x,"r(kc)=",f7.4,2x,"time/tscale=",f9.6)
c
c  write data
c
      write(21,2101) (b(lm,1),lm=1,nlma)
c      write(21,2102) (w(lm,kc),lm=1,nlma)
c      write(21,2102) (dw(lm,kc),lm=1,nlma)
c      write(21,2102) (z(lm,kc),lm=1,nlma)
 2101 format(256(1X,f9.5))
 2102 format(256(1X,f9.3))
 
c processing unscramble start here
      write(22,2200) nlma,lmax,minc,r(1),r(kc),time/tscale
 2200 format(/, 2x,"nlma=",i3,2x,"lmax=",i3,2x,"minc=",i3,2x,
     $   "r(1)=",f7.4,2x,"r(kc)=",f7.4,2x,"time/tscale=",f9.6)

c define intermediate indices  
c defined in param.f
c      mmax=(lmax/minc)*minc
c      nmaf=mmax+1
c      nlaf=lmax+1
c print out mmax nmaf and nlaf 
c      write(22,2203) mmax,nmaf,nlaf
c 2203 format(/,2x,3i3)

c define the unscramble array mclm(lm) 	
      lm=0
      do 35 mc=1,nmaf,minc
      do 31 lc=mc,nlaf
       lm=lm+1
       mclm(lm)=mc
      write(22,2201) lm, mclm(lm)
 2201 format(/, 2x,i3,2x,i4)     
   31 continue
   35 continue

c define la, ma arrays
      do 36 lm=1,nlma
       ma(lm)=mclm(lm)-1
c define al in three terms
       tl1=lm+ma(lm)-1
       tl2=ma(lm)*(ma(lm)-minc)/(2.*minc)
       tl3=-ma(lm)*(lmax+1)/minc
       la(lm)=tl1+tl2+tl3
c PRINT lm, la(lm), ma(lm) HERE
      write(22,2202) lm, la(lm), ma(lm)
 2202 format(/, 2x,i3,2x,i4,2x,i4)	  
   36 continue
c

c then read the contents of the cc-file block in pairs,
c and assign the new indices

      do 37 lm=1,nlma
cc     READ (cc-file) c1,c2
c assign new indices
      l=la(lm)
      m=ma(lm)
      alm(l,m)=c1
      blm(l,m)=c2

c   Convertion starts here
c   the following code converts between Gauss coefficients (glm, hlm)
c       and the spherical harmonic coefficients (alm,blm)
c   of the magnetic potential at harmonic degree l
c   and order m used by the numerical dynamo model MAG.
c
c   Inputs:
c       l,m: integer spherical harmonic degree and order;
c
c       id: transformation direction:
c           id = 1 converts (alm,blm) to (glm,hlm)
c           id =-1 converts (glm,hlm) to (alm,blm)
c
c       alm,blm: dimensionless spherical harmonic coefficients
c           of the radial magnetic field potential on the
c           outer boundary of the dynamo model. alm is the
c           coefficient of the real (cosine) part and blm
c           is for the imaginary (sine) part.
c
c       glm,hlm: Gauss coefficients in nanotessla   (nT).
c                        glm multiplies with cos(m*phi)
c                        hlm multiplies with sin(m*phi)
c
c   The calculation uses SI units and nominal Earth values for
c   surface and core radii. The
c   conversion from dimensionless (alm,blm) to (glm,hlm) in
c   nT uses Earth values for density, rotation, electrical
c   conductivity, and uses the depth of the outer core as the
c   length scale.

      if (l .le. 0 .or. m .lt. 0 .or. m .gt. l) then
       write(6,'(''bad l or m in getgauss'')')
       return
      endif

      if (id .gt. 0) then  ! form Gauss coeffs in nT
         glm(l,m)=anano*escale*fact2*conalm*alm(l,m)
         hlm(l,m)=anano*escale*fact2*conblm*blm(l,m)
           return
      else ! form dimensionless fully normalized potential coeffs
         alm(l,m)=glm(l,m)/(anano*escale*fact2*conalm)
         blm(l,m)=hlm(l,m)/(anano*escale*fact2*conblm)
      return
      endif

   37 continue

      return 
      end
