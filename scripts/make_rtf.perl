#!/usr/bin/perl
# Writes a Topolgy file from a PDB file

# Difficulties in finding types of atom for :
#         - Heterocycles (aromatic)
#         - Conjugated double bonds
#         - Guanidiniums


if ($ARGV[0] ne "-n" and $ARGV[0] ne "-c") { die "Wrong options";}


open(INPUT,"$ARGV[1]");

@pdb=<INPUT>;


# --- Covalence radius

$C=0.8;
$H=0.4;
$O=0.8;
$N=0.8;
$S=1.2;
$P=1.2;
$F=1.3;

#$C=0.8;
#$H=0.6;
#$O=0.8;
#$N=1.6;
#$S=1.2;
#$P=1.2;

# --- Reading PDB file

foreach $i (0..@pdb){
    @term=split(' ', $pdb[$i]);
    if ($term[0] eq "ATOM") {
    $x[$term[1]]=$term[5];
    $y[$term[1]]=$term[6];
    $z[$term[1]]=$term[7];
    $name[$term[1]]=$term[2];
    $charge[$i]=0;
    $type[$term[1]]="UNK";
    $atom[$term[1]]=uc(substr($term[2],0,1));
    if (($atom[$term[1]] ne "C") and ($atom[$term[1]] ne "H") and ($atom[$term[1]] ne "O") and ($atom[$term[1]] ne "N") and ($atom[$term[1]] ne "S") and ($atom[$term[1]] ne "P") and ($atom[$term[1]] ne "F")) {
    $atom[$term[1]]=uc(substr($term[2],1,1));
    }
    $res_name=$term[3];
    $num=$num+1;
    };
};


# --- Calculating charges if asked


if ($ARGV[0] eq "-c") {
#  system "tcsh; setenv BABEL_DIR /usr/etc/babel; babel -ipdb $ARGV[1] -omopint temp.dat \"AM1 1SCF MMOK \"";
system "babel -ipdb $ARGV[1] -omopin temp.dat \"AM1 GNORM=1 MMOK \"";
system "mopac7 temp > /dev/null";
open(MOPAC,"temp.out");
@line=<MOPAC>;
foreach $i (0..@line) {
    $test1=substr($line[$i],0,57);
    $test2="              NET ATOMIC CHARGES AND DIPOLE CONTRIBUTIONS";
    if ($test1 eq $test2) {
    for ($j=1;$j<$num+1;$j++) {
    @s=split(' ',$line[$i+$j+2]);
    $charge[$j]=$s[2];
    };
    };
};
unlink("temp.dat");
unlink("temp.out");
unlink("temp.arc");
for ($i=1;$i<$num+1;$i++) {
    $charge_tot+=$charge[$i];
};
if ($charge_tot != 0) {
    $charge[1]=$charge[1]-$charge_tot;
};
}


# --- Determination of bonds

for ($i=1;$i<$num+1;$i++) {
for ($j=$i+1;$j<$num+1;$j++) {
    $dist=sqrt(($x[$i]-$x[$j])**2+($y[$i]-$y[$j])**2+($z[$i]-$z[$j])**2);
    if ($dist < ${$atom[$i]} + ${$atom[$j]}) {
    $num_bond+=1;
    $bond[$num_bond][1]=$i; 
    $bond[$num_bond][2]=$j;
    $bond_length[$i][$j]=$dist;
    $bond_length[$j][$i]=$dist;
    $num_link[$i]+=1;
    $num_link[$j]+=1;
    $link[$i][$num_link[$i]]=$j; #!!
    $link[$j][$num_link[$j]]=$i; #!!
    $bound{$atom[$j]}[$i]+=1; #!!
    $bound{$atom[$i]}[$j]+=1; #!!
    };
};
}

# --- Determination of hybridation

for ($i=1;$i<$num+1;$i++) {
if ($atom[$i] eq "C") {
    if ($num_link[$i]==4) {
    $hybrid[$i]="sp3";
    } elsif ($num_link[$i]==3) {
    $hybrid[$i]="sp2";
    } elsif ($num_link[$i]==2) {
    $hybrid[$i]="sp";
    };
};
};

for ($i=1;$i<$num+1;$i++) {
if ($atom[$i] eq "O") {
    if ($num_link[$i]==2) {
    $hybrid[$i]="sp3";
    };
    if ($num_link[$i]==1) {
    $hybrid[$i]="sp2";
    };
};
};

for ($i=1;$i<$num+1;$i++) {
if ($atom[$i] eq "N") {
    if ($num_link[$i]==4) {
    $hybrid[$i]="sp3";
    } elsif ($num_link[$i]==1) {
    $hybrid[$i]="sp";
    } elsif ($num_link[$i]==2) {
    $hybrid[$i]="sp2";
    } elsif ($num_link[$i]==3) {
    if (($hybrid[$link[$i][1]] eq "sp2") or ($hybrid[$link[$i][2]] eq "sp2") or ($hybrid[$link[$i][3]] eq "sp2")) {
    $hybrid[$i]="sp2";
    } else { 
    $hybrid[$i]="sp3"; 
    };
    };
};
};


# --- Determination of type

for ($loop=1;$loop<3;$loop++) {

for ($i=1;$i<$num+1;$i++) {

if ($atom[$i] eq "C") {
    if ($hybrid[$i] eq "sp3") {
        if ($bound{"H"}[$i]==3) { $type[$i]="CT3"; }
    elsif ($bound{"H"}[$i]==4) { $type[$i]="CT3"; }
    elsif ($bound{"H"}[$i]==2) { $type[$i]="CT2"; }
    else { $type[$i]="CT1"; }
    } 
    elsif ($hybrid[$i] eq "sp2") {
    if ($bound{"C"}[$i]==3) {
        if ($hybrid[$link[$i][1]] eq "sp2" and $hybrid[$link[$i][2]] eq "sp2" and $hybrid[$link[$i][3]] eq "sp2") { $type[$i]="CA"; }
        elsif (($hybrid[$link[$i][1]] eq "sp2" and $hybrid[$link[$i][2]] eq "sp2") or ($hybrid[$link[$i][1]] eq "sp2" and $hybrid[$link[$i][3]] eq "sp2") or ($hybrid[$link[$i][2]] eq "sp2" and $hybrid[$link[$i][3]] eq "sp2")) { $type[$i]="CA"; }
        elsif (($hybrid[$link[$i][1]] eq "sp3" and $hybrid[$link[$i][2]] eq "sp3") or ($hybrid[$link[$i][1]] eq "sp3" and $hybrid[$link[$i][3]] eq "sp3") or ($hybrid[$link[$i][2]] eq "sp3" and $hybrid[$link[$i][3]] eq "sp3")) { $type[$i]="CE1"; }
    }
    elsif ($bound{"C"}[$i]==2) {
        if (($hybrid[$link[$i][1]] eq "sp2" and $hybrid[$link[$i][2]] eq "sp2") or ($hybrid[$link[$i][1]] eq "sp2" and $hybrid[$link[$i][3]] eq "sp2") or ($hybrid[$link[$i][2]] eq "sp2" and $hybrid[$link[$i][3]] eq "sp2")) { $type[$i]="CA"; }
        elsif (($hybrid[$link[$i][1]] eq "sp3" and $hybrid[$link[$i][2]] eq "sp3") or ($hybrid[$link[$i][1]] eq "sp3" and $hybrid[$link[$i][3]] eq "sp3") or ($hybrid[$link[$i][2]] eq "sp3" and $hybrid[$link[$i][3]] eq "sp3")) {
        if ($bound{"O"}[$i]==1 or $bound{"N"}[$i]==1) { $type[$i]="C"; }
        }		
        elsif ($bound{"H"}[$i]==1) { $type[$i]="CE1"; }
        elsif ($bound{"H"}[$i]==1 or $bound{"N"}[$i]==1) { $type[$i]="C"; }
        if ($type[$i] eq "CA" and (substr($type[$link[$i][1]],0,2) eq "NR" or substr($type[$link[$i][2]],0,2) eq "NR" or substr($type[$link[$i][3]],0,2) eq "NR")) { $type[$i]="CPH1"}
    } 
    elsif ($bound{"C"}[$i]==1) {
        if ($bound{"N"}[$i]==1 and $bound{"O"}[$i]==1) { $type[$i]="C"; }
        elsif ($bound{"O"}[$i]==2) { $type[$i]="CC"; }
        elsif ($bound{"N"}[$i]==1 and $bound{"H"}[$i]==1) {
        if ($type[$link[$i][1]] eq "CA" or $type[$link[$i][2]] eq "CA" or $type[$link[$i][3]] eq "CA") { $type[$i]="CPH2" }
        else { $type[$i]="CA"; }
        }
        elsif ($bound{"H"}[$i]==2) { $type[$i]="CE2"; }
    }
    elsif ($bound{"N"}[$i]==3) {  $type[$i]="C"; }
    elsif ($bound{"N"}[$i]==2 and $bound{"O"}[$i]==1) { $type[$i]="C"; }
    elsif ($bound{"N"}[$i]==2 and $bound{"H"}[$i]==1) { $type[$i]="CPH2"; }
    } 
    else { $type[$i]="UNK"; }
}
}


#second loop on atoms for "O"
for ($i=1;$i<$num+1;$i++) {

if ($atom[$i] eq "O") {
    if ($num_link[$i]==1) {
        if ($type[$link[$i][1]] eq "C") { $type[$i]="O"; }
    elsif ($type[$link[$link[$i][1]][1]] eq "OH1" or $type[$link[$link[$i][1]][2]] eq "OH1" or $type[$link[$link[$i][1]][3]] eq "OH1") { $type[$i]="OB"; }
    elsif ($type[$link[$link[$i][1]][1]] eq "OS" or $type[$link[$link[$i][1]][2]] eq "OS" or $type[$link[$link[$i][1]][3]] eq "OS") { $type[$i]="OB"; }
        elsif ($type[$link[$i][1]] eq "CC") { $type[$i]="OC"; }
    }
    elsif ($num_link[$i]==2) {
    if ($bound{"H"}[$i]==2) { $type[$i]="OT"; }
    elsif ($bound{"H"}[$i]==1) {
        if ($type[$link[$i][1]] eq "CC" or $type[$link[$i][2]] eq "CC") { $type[$i]="OH1"; }
        elsif ($type[$link[$i][1]] ne "CC" and $type[$link[$i][2]] ne "CC") { $type[$i]="OH1"; }
        else { $type[$i]="UNK"; }
    }
    elsif ($bound{"C"}[$i]==2) { 
    if ($type[$link[$i][1]] eq "CC" or $type[$link[$i][2]] eq "CC") { $type[$i]="OS"; }
    else  { $type[$i]="UNK"; }
    }
    }
}
}




for ($i=1;$i<$num+1;$i++) {

if ($atom[$i] eq "N") {
    if ($hybrid[$i] eq "sp3") {
        if ($bound{"H"}[$i]==3) { $type[$i]="NH3"; }
        elsif ($bound{"H"}[$i]==2 or $bound{"H"}[$i]==1) { $type[$i]="NP"; }
    elsif ($bound{"C"}[$i]==3) { $type[$i]="NP"; }
    }
    elsif ($hybrid[$i] eq "sp2") {
        if ($type[$link[$i][1]] eq "CA" or $type[$link[$i][2]] eq "CA" or $type[$link[$i][3]] eq "CA") { $type[$i]="NH2"; }   # aniline
    elsif (($type[$link[$i][1]] eq "C" or $type[$link[$i][2]] eq "C" or $type[$link[$i][3]] eq "C") and ($bound{H}[$i]==2)) { $type[$i]="NH2"; }   # secondary amide
    elsif (($type[$link[$i][1]] eq "C" or $type[$link[$i][2]] eq "C" or $type[$link[$i][3]] eq "C") and ($bound{H}[$i]==1)) { $type[$i]="NH1"; }   # primary amide
    elsif (($type[$link[$i][1]] eq "C" or $type[$link[$i][2]] eq "C" or $type[$link[$i][3]] eq "C") and ($bound{H}[$i]==0)) { $type[$i]="N"; }     # proline type N peptide
    if ($bound{"C"}[$i]==2 and $bound{"H"}[$i]==0) {
        if (substr($type[$link[$i][1]],0,3) eq "CPH" or substr($type[$link[$i][2]],0,3) eq "CPH") { $type[$i]="NR2"; }
    }
    if ($bound{"C"}[$i]==2 and $bound{"H"}[$i]==1) {
        if (substr($type[$link[$i][1]],0,3) eq "CPH" or substr($type[$link[$i][2]],0,3) eq "CPH" or substr($type[$link[$i][3]],0,3) eq "CPH") { $type[$i]="NR1"; }
    }
    }
}
}      



for ($i=1;$i<$num+1;$i++) {

if ($atom[$i] eq "S") {
    if ($bound{"C"}[$i]==2) { $type[$i]="S" }
    if ($bound{"C"}[$i]==1 and $bound{"H"}[$i]==1) {  $type[$i]="S" }
    if ($bound{"C"}[$i]==1 and $bound{"S"}[$i]==1) {  $type[$i]="SM" }
}
}

for ($i=1;$i<$num+1;$i++) {

if ($atom[$i] eq "H") {
    if ($bound{"N"}[$i]==1)  { $type[$i]="H"; }
    elsif ($bound{"O"}[$i]==1) {
    if ($type[$link[$i][1]] eq "OH1") { $type[$i]="H"; }
    if ($type[$link[$i][1]] eq "OT") { $type[$i]="HT"; }
    }
    elsif ($bound{"S"}[$i]==1) { $type[$i]="HS"; }
    elsif ($bound{"C"}[$i]==1) {
    if ($hybrid[$link[$i][1]] eq "sp3") { $type[$i]="HA"; }
    elsif ($type[$link[$i][1]] eq "CE1") { $type[$i]="HA1"; }
    elsif ($type[$link[$i][1]] eq "CE2") { $type[$i]="HA2"; }
    elsif ($type[$link[$i][1]] eq "CA") { $type[$i]="HP"; }
    elsif ($type[$link[$i][1]] eq "CPH1") { $type[$i]="HR3"; }
    elsif ($type[$link[$i][1]] eq "CPH2") { $type[$i]="HR1"; }
    } else { $type[$i]="UNK"; }
}
}

### CAF ###
for ($i=1;$i<$num+1;$i++) {

if ($atom[$i] eq "Br") {
    $type[$i]="BR" }
}
### CAF ###



# --- Finds IMPROPER

for ($i=1;$i<$num+1;$i++) {
if ((($atom[$i] eq "C") or ($atom[$i] eq "N")) and ($hybrid[$i] eq "sp2") and ($type[$i] ne "NR2")) {
    $num_imph+=1;
    $IMPH[$num_imph][1]=$i;
    $IMPH[$num_imph][2]=$link[$i][1];
    $IMPH[$num_imph][3]=$link[$i][2];
    $IMPH[$num_imph][4]=$link[$i][3];
};
};


}

# --- Calculates IC
        
$num_ic=0;
for ($i=1;$i<$num+1;$i++) {
for ($j=1;$j<$num_link[$i]+1;$j++) {
    $l1=$link[$i][$j];
    for ($k=1;$k<$num_link[$l1]+1;$k++) {
    $l2=$link[$l1][$k];
    if ($l2 != $i){
    for ($l=1;$l<$num_link[$l2]+1;$l++) {
    $l3=$link[$l2][$l];
    if (($l3 != $i) and ($l3 != $l1)) {
        $test=0;
        for ($m=0;$m<$num_ic+1;$m++) {
        if (($i == $IC[$m][4]) and ($l1 == $IC[$m][3]) and ($l2 == $IC[$m][2]) and ($l3 == $IC[$m][1])) {
        $test=1;
        };
        };
        if ($test==0) {
        $num_ic+=1;
        $IC[$num_ic][1]=$i;
        $IC[$num_ic][2]=$l1;
        $IC[$num_ic][3]=$l2;
        $IC[$num_ic][4]=$l3;
        $IC[$num_ic][5]=0;   # Not an improper IC
        $IC[$num_ic][6]=$bond_length[$i][$l1];  # Distance between A and B
        $IC[$num_ic][7]=(180/3.1415927)*calcul_angle($IC[$num_ic][1],$IC[$num_ic][2],$IC[$num_ic][3]);    # Angle ABC
        $IC[$num_ic][8]=(180/3.1415927)*calcul_dihedral($IC[$num_ic][1],$IC[$num_ic][2],$IC[$num_ic][3],$IC[$num_ic][4]);    # Dihedral ABCD
        $IC[$num_ic][9]=(180/3.1415927)*calcul_angle($IC[$num_ic][2],$IC[$num_ic][3],$IC[$num_ic][4]);    # Angle BCD
        $IC[$num_ic][10]=$bond_length[$l2][$l3];  # Distance between C and D
        };
    };
    };
    };
    };
};
};

if ($num_imph != 0) {
for ($i=1;$i<$num_imph+1;$i++) {
    $num_ic+=1;
    $IC[$num_ic][1]=$IMPH[$i][2];
    $IC[$num_ic][2]=$IMPH[$i][3];
    $IC[$num_ic][3]=$IMPH[$i][1];
    $IC[$num_ic][4]=$IMPH[$i][4];
    $IC[$num_ic][5]=1;      # Improper IC
    $IC[$num_ic][6]=$bond_length[$IC[$num_ic][1]][$IC[$num_ic][3]];  # Distance between A and B
    $IC[$num_ic][7]=(180/3.1415927)*calcul_angle($IC[$num_ic][1],$IC[$num_ic][3],$IC[$num_ic][2]);    # Angle ACB
    $IC[$num_ic][8]=(180/3.1415927)*calcul_dihedral($IC[$num_ic][1],$IC[$num_ic][2],$IC[$num_ic][3],$IC[$num_ic][4]);    # Dihedral ABCD
    $IC[$num_ic][9]=(180/3.1415927)*calcul_angle($IC[$num_ic][2],$IC[$num_ic][3],$IC[$num_ic][4]);    # Angle BCD
    $IC[$num_ic][10]=$bond_length[$IC[$num_ic][3]][$IC[$num_ic][4]];  # Distance between C and D

};
};


# --- Writing Topology file

print "* ... \n";
print "* Build RTF for $ARGV[1] \n";
print "* ...\n*\n";

print "   22    0 \n\n";

print "AUTOGENERATE ANGLES DIHE\n";
print "DEFA FIRS NONE LAST NONE\n\n";

printf ("RESI %3s   0.000\n", $res_name);
print "GROUP\n";

for ($i=1;$i<$num+1;$i++) {
print "ATOM $name[$i] $type[$i] ";
printf("%6.4f \n", $charge[$i]);
};

for ($i=1;$i<$num_bond+1;$i++) {
print "BOND $name[$bond[$i][1]] $name[$bond[$i][2]]\n";
};

if ($num_imph != 0) {
for ($i=1;$i<$num_imph+1;$i++) {
    print "IMPH $name[$IMPH[$i][1]] $name[$IMPH[$i][2]] $name[$IMPH[$i][3]] $name[$IMPH[$i][4]]\n";
};
};

for ($i=1;$i<$num_ic+1;$i++) {
print "IC $name[$IC[$i][1]] $name[$IC[$i][2]]";
if ($IC[$i][5] == 1) {
    print " *";
} else {
    print "  ";
};
print "$name[$IC[$i][3]] $name[$IC[$i][4]]   ";
printf("%4.2f %7.2f %7.2f %7.2f   %4.2f\n", $IC[$i][6],$IC[$i][7],$IC[$i][8],$IC[$i][9],$IC[$i][10]);
};

print "\nEND\n";

close(INPUT);

sub calcul_angle {

    $a=@_[0];
    $b=@_[1];
    $c=@_[2];


    $vec_x[1]=$x[$a]-$x[$b];
    $vec_y[1]=$y[$a]-$y[$b];
    $vec_z[1]=$z[$a]-$z[$b];
    $vec_x[2]=$x[$c]-$x[$b];
    $vec_y[2]=$y[$c]-$y[$b];
    $vec_z[2]=$z[$c]-$z[$b];


    $norm[1]=sqrt(($vec_x[1])**2+($vec_y[1])**2+($vec_z[1])**2);
    $norm[2]=sqrt(($vec_x[2])**2+($vec_y[2])**2+($vec_z[2])**2);

    $scalaire=($vec_x[1]*$vec_x[2])+($vec_y[1]*$vec_y[2])+($vec_z[1]*$vec_z[2]);
    

    $angle=acos($scalaire/($norm[1]*$norm[2]));

    return $angle;
    
};



sub calcul_dihedral { 

    $a=@_[0];
    $b=@_[1];
    $c=@_[2];
    $d=@_[3];


    $vec_x[1]=$x[$a]-$x[$b];
    $vec_y[1]=$y[$a]-$y[$b];
    $vec_z[1]=$z[$a]-$z[$b];
    
    $vec_x[2]=$x[$d]-$x[$c];
    $vec_y[2]=$y[$d]-$y[$c];
    $vec_z[2]=$z[$d]-$z[$c];
    
    $vec_x[3]=$x[$b]-$x[$c];
    $vec_y[3]=$y[$b]-$y[$c];
    $vec_z[3]=$z[$b]-$z[$c];


    $pro_vec_x[1]=($vec_y[1]*$vec_z[3])-($vec_z[1]*$vec_y[3]);
    $pro_vec_y[1]=($vec_z[1]*$vec_x[3])-($vec_x[1]*$vec_z[3]);
    $pro_vec_z[1]=($vec_x[1]*$vec_y[3])-($vec_y[1]*$vec_x[3]);

    $pro_vec_x[2]=($vec_y[2]*$vec_z[3])-($vec_z[2]*$vec_y[3]);
    $pro_vec_y[2]=($vec_z[2]*$vec_x[3])-($vec_x[2]*$vec_z[3]);
    $pro_vec_z[2]=($vec_x[2]*$vec_y[3])-($vec_y[2]*$vec_x[3]);

    $norm[1]=sqrt(($pro_vec_x[1])**2+($pro_vec_y[1])**2+($pro_vec_z[1])**2);
    $norm[2]=sqrt(($pro_vec_x[2])**2+($pro_vec_y[2])**2+($pro_vec_z[2])**2);

    $scalaire=($pro_vec_x[1]*$pro_vec_x[2])+($pro_vec_y[1]*$pro_vec_y[2])+($pro_vec_z[1]*$pro_vec_z[2]);
    
    $pro_vec_x[3]=($vec_y[2]*$vec_z[1])-($vec_z[2]*$vec_y[1]);
    $pro_vec_y[3]=($vec_z[2]*$vec_x[1])-($vec_x[2]*$vec_z[1]);
    $pro_vec_z[3]=($vec_x[2]*$vec_y[1])-($vec_y[2]*$vec_x[1]);

    $scalaire_for_sign=($pro_vec_x[3]*$vec_x[3])+($pro_vec_y[3]*$vec_y[3])+($pro_vec_z[3]*$vec_z[3]);

    if ($scalaire_for_sign < 0) {
    $sign=-1;
    } else {
    $sign=1;
    };

    $dihedral=$sign*acos($scalaire/($norm[1]*$norm[2]));


    return $dihedral;


}

sub acos { atan2( sqrt(1-$_[0]*$_[0]), $_[0]) }


end


