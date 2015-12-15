/*
 * Copyright (c) 2015, Florent Hedin, Markus Meuwly, and the University of Basel
 * All rights reserved.
 *
 * The 3-clause BSD license is applied to this software.
 * see LICENSE.txt
 *
 */
package ch.unibas.charmmtools.gui.database.interfaces;

import ch.unibas.charmmtools.gui.database.dataModel.DB_model;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import org.apache.log4j.Logger;

/**
 * This abstract class manages a connection to a database for finding chemical
 * compounds properties
 *
 * @author hedin
 */
public abstract class DB_interface {

    protected static final Logger logger = Logger.getLogger(DB_interface.class);

    protected static final String colId = "id";
    protected static final String colIdpubchem = "idPubchem";
    protected static final String colName = "name";
    protected static final String colInchi = "inchi";
    protected static final String colFormula = "formula";
    protected static final String colSmiles = "smiles";
    protected static final String colMass = "mass";
    protected static final String colDensity = "density";
    protected static final String colHvap = "Hvap";
    protected static final String colGsolv = "Gsolv";

    protected Connection connect = null;

    /**
     *
     * @param rset
     * @return
     */
    protected List<DB_model> parseResultSet(ResultSet rset) {

        List<DB_model> parsedList = new ArrayList<>();
                 
        try {
            // then parse result
            while (rset.next()) {
                int id = Integer.valueOf(rset.getString(colId));
                int idpubchem = Integer.valueOf(rset.getString(colIdpubchem));
                String name = rset.getString(colName);
                String formula = rset.getString(colFormula);
                String inchi = rset.getString(colInchi);
                String smiles = rset.getString(colSmiles);
                String mass = rset.getString(colMass);
                String density = rset.getString(colDensity);
                String dh = rset.getString(colHvap);
                String dg = rset.getString(colGsolv);
                parsedList.add(new DB_model(id, idpubchem,
                        name, formula, inchi, smiles,
                        mass, density, dh, dg));
            }
        } catch (SQLException ex) {
            logger.error("Error when parsing ResultSet of SQL statement in parseResultSet() ! " + ex.getMessage());
        }

        return parsedList;
    }

    /**
     * Find data using compound name
     *
     * @param name
     * @return
     */
    public List<DB_model> findByName(String name) {

//        PreparedStatement statement = null;
        Statement statement = null;
        ResultSet resultSet = null;
        List<DB_model> modelList = null;

        try {
            //prepare statement and execute it
//            statement = connect.prepareStatement(byNameQuery);
//            statement.setString(1, name);
            statement = connect.createStatement();
            resultSet = statement.executeQuery(
                      "select `compounds`.id, `compounds`.idPubchem, `compounds`.name,"
                    + " `structure`.formula, `structure`.inchi, `structure`.smiles,"
                    + " `prop`.mass, `prop`.density, `prop`.Hvap, `prop`.Gsolv"
                    + " from `compounds`,`prop`,`structure` where `compounds`.name like '%" + name + "%'"
                    + " and compounds.id=prop.id and compounds.id=structure.id"
                    + " order by compounds.id"
            );
            modelList = parseResultSet(resultSet);
        } catch (SQLException ex) {
            logger.error("Error when executing SQL statement in findByName() ! " + ex.getMessage());
        }

//        logger.info("Statement was : " + statement.toString());
        
        return modelList;
    }

    /**
     * Find data using compound formula
     *
     * @param formula
     * @return
     */
    public List<DB_model> findByFormula(String formula) {

        Statement statement = null;
        ResultSet resultSet = null;
        List<DB_model> modelList = null;

        try {
            //prepare statement and execute it
            statement = connect.createStatement();
            resultSet = statement.executeQuery(
                    "select `compounds`.id, `compounds`.idPubchem, `compounds`.name,"
                    + " `structure`.formula, `structure`.inchi, `structure`.smiles,"
                    + " `prop`.mass, `prop`.density, `prop`.Hvap, `prop`.Gsolv"
                    + " from `compounds`,`prop`,`structure` where `structure`.formula like '%" + formula + "%'"
                    + " and compounds.id=prop.id and compounds.id=structure.id"
                    + " order by compounds.id"
            );
            modelList = parseResultSet(resultSet);
        } catch (SQLException ex) {
            logger.error("Error when executing SQL statement in findByFormula() ! " + ex.getMessage());
        }

        return modelList;
    }

    /**
     * Find data using compound SMILES notation
     *
     * @param smiles
     * @return
     */
    public List<DB_model> findBySMILES(String smiles) {

        Statement statement = null;
        ResultSet resultSet = null;
        List<DB_model> modelList = null;

        try {
            //prepare statement and execute it
            statement = connect.createStatement();
            resultSet = statement.executeQuery(
                      "select `compounds`.id, `compounds`.idPubchem, `compounds`.name,"
                    + " `structure`.formula, `structure`.inchi, `structure`.smiles,"
                    + " `prop`.mass, `prop`.density, `prop`.Hvap, `prop`.Gsolv"
                    + " from `compounds`,`prop`,`structure` where `structure`.smiles like '%" + smiles + "%'"
                    + " and `compounds`.id=`prop`.id and `compounds`.id=`structure`.id"
                    + " order by `compounds`.id"
            );
            modelList = parseResultSet(resultSet);
        } catch (SQLException ex) {
            logger.error("Error when executing SQL statement in findBySMILES() ! " + ex.getMessage());
        }

        return modelList;
    }

    /**
     * Find data using compound value + or - a threshold
     *
     * @param value_type
     * @param target
     * @param threshold
     * @return
     */
    public List<DB_model> findByValue(String value_type, double target, double threshold) {

        Statement statement = null;
        ResultSet resultSet = null;
        List<DB_model> modelList = null;

        String property = null;

        switch (value_type) {
            case "Mass":
                property = "`prop`.mass";
                break;

            case "Density":
                property = "`prop`.density";
                break;

            case "ΔH":
                property = "`prop`.Hvap";
                break;

            case "ΔG":
                property = "`prop`.Gsolv";
                break;

            default:
                property = "`prop`.mass";
                break;
        }

        double massHigh = target + threshold;
        double massLow = target - threshold;

        try {
            //prepare statement and execute it
            statement = connect.createStatement();
            resultSet = statement.executeQuery(
                      "select `compounds`.id, `compounds`.idPubchem, `compounds`.name,"
                    + " `structure`.formula, `structure`.inchi, `structure`.smiles,"
                    + " `prop`.mass, `prop`.density, `prop`.Hvap, `prop`.Gsolv"
                    + " from `compounds`,`prop`,`structure` where " + property + " between " + massLow + " and " + massHigh
                    + " and `compounds`.id=`prop`.id and `compounds`.id=`structure`.id"
                    + " order by `compounds`.id"
            );
            modelList = parseResultSet(resultSet);
        } catch (SQLException ex) {
            logger.error("Error when executing SQL statement in findByMASS() ! " + ex.getMessage());
        }

        return modelList;
    }

    /**
     * Returns name of the connection currently used
     * @return A string representation of the connection
     */
    public abstract String getConnectionName();
    
    /**
     * Updates records from the DataBase using a given data model
     * 
     * @param model The model to use containing values of DataBase to ipdate
     */
    public void updateRecord(DB_model model)
    {
        Statement statement = null;
        int status ;
        
        try {
            //prepare statement and execute it
            statement = connect.createStatement();
            String sql = 
                    "update `compounds`,`prop`,`structure` set"
                    + " `compounds`.name='" + model.getName() + "',"
                    + " `structure`.formula='" + model.getFormula() + "',"
                    + " `structure`.inchi='" + model.getInchi() + "',"
                    + " `structure`.smiles='" + model.getSmiles() + "',"
                    + " `prop`.mass=" + model.getMass() + ","
                    + " `prop`.density='" + model.getDensity() + "',"
                    + " `prop`.Hvap='" + model.getDh() + "',"
                    + " `prop`.Gsolv='" + model.getDg() + "'"
                    + " where `compounds`.id=" + model.getId()
                    + " and `compounds`.id=`prop`.id and `compounds`.id=`structure`.id";
            
            logger.info("Executing statement : " + sql);
            
            status = statement.executeUpdate(sql);

        } catch (SQLException ex) {
            logger.error("Error when executing SQL statement in updateRecord() ! " + ex.getMessage());
        }
    }
    
}
