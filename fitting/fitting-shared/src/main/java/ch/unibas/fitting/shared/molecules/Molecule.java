/*
 * Copyright (c) 2015, Florent Hedin, Markus Meuwly, and the University of Basel
 * All rights reserved.
 *
 * The 3-clause BSD license is applied to this software.
 * see LICENSE.txt
 *
 */
package ch.unibas.fitting.shared.molecules;

import ch.unibas.fitting.shared.xyz.XyzFile;
import org.joda.time.DateTime;

import java.io.File;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;

/**
 * User: mhelmer
 * Date: 25.11.13
 * Time: 14:39
 */
public class Molecule {
    private final XyzFile xyzFile;
    private final MoleculeId id;
    private final File lpunFile;
    private final List<Atom> atoms;
    private final List<AtomType> atomTypes;
    private final DateTime created;
    private File mtpFitTabFile;

    public Molecule(XyzFile xyzFile,
                    File lpunFile,
                    File mtpFitTabFile,
                    List<Atom> atoms,
                    List<AtomType> atomTypes) {
        this.xyzFile = xyzFile;
        this.id = new MoleculeId(xyzFile.getMoleculeName());
        this.lpunFile = lpunFile;
        this.mtpFitTabFile = mtpFitTabFile;
        this.atoms = atoms;
        this.atomTypes = atomTypes;
        this.created = DateTime.now();
        verifyUserChargeState();
        verifyIndices();
    }

    private void verifyUserChargeState() {
        UserChargesState userChargesState = checkChargesState(atomTypes);
        if (userChargesState == UserChargesState.Invalid)
            throw new IllegalArgumentException("Either all or no user charges must be defined.");
    }

    private void verifyIndices() {
        int indicesCount = 0;
        for (AtomType atomType : atomTypes) {
            indicesCount += atomType.getIndices().length;
        }
        if (atoms.size() != indicesCount)
            throw new IllegalArgumentException("Atom count does not match atom charge count.");
    }

    public static UserChargesState checkChargesState(List<AtomType> charges) {
        UserChargesState state = UserChargesState.Invalid;

        int userChargesDefinedCount = 0;
        for (int i = 0; i < charges.size(); i++) {
            AtomType charge = charges.get(i);
            if (charge.getUserQ00() != null)
                userChargesDefinedCount++;
        }
        if (userChargesDefinedCount == 0)
            state = UserChargesState.NoChargesDefined;
        else if (userChargesDefinedCount == charges.size())
            state = UserChargesState.AllChargesDefined;

        return state;
    }

    public void setUserCharge(String name, Double newCharge) {
        Optional<AtomType> type = findAtomTypeByName(name);
        if (type.isPresent())
            type.get().setUserQ0(newCharge);
    }

    public String getDescription() {
        return id.getDescription();
    }

    public boolean containsAtomType(AtomTypeId atomTypeId) {
        return findAtomTypeById(atomTypeId) != null;
    }

    public Optional<AtomType> findAtomTypeByName(String name) {
        return findAtomTypeById(new AtomTypeId(name));
    }

    public Optional<AtomType> findAtomTypeById(AtomTypeId id) {
        for (AtomType atomType : atomTypes) {
            if (atomType.getId().equals(id))
                return Optional.of(atomType);
        }
        return Optional.empty();
    }

    public UserChargesState getUserChargesState() {
        return checkChargesState(atomTypes);
    }

    public MoleculeId getId() {
        return id;
    }

    public XyzFile getXyzFile() {
        return xyzFile;
    }

    public File getLpunFile() {
        return lpunFile;
    }

    public List<Atom> getAtoms() {
        return atoms;
    }

    public List<AtomType> getAtomTypes() {
        return atomTypes;
    }

    @Override
    public String toString() {
        return "Molecule{" +
                "id=" + id +
                ", atoms=" + atoms +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        Molecule molecule = (Molecule) o;

        if (!id.equals(molecule.id)) return false;

        return true;
    }

    @Override
    public int hashCode() {
        return id.hashCode();
    }

    public LinkedHashSet<AtomTypeId> getAllAtomTypeIds() {
        LinkedHashSet<AtomTypeId> all = new LinkedHashSet<>();
        for (AtomType atomType : atomTypes) {
            all.add(atomType.getId());
        }
        return all;
    }

    public DateTime getCreated() {
        return created;
    }

    public File getMtpFitTabFile() {
        return mtpFitTabFile;
    }

    public enum UserChargesState {
        Invalid,
        AllChargesDefined,
        NoChargesDefined
    }
}
