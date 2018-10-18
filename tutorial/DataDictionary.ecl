EXPORT DataDictionary := MODULE

    EXPORT Layout_Person := RECORD
        UNSIGNED3 PersonID;
        STRING15 FirstName;
        STRING25 LastName;
        STRING1   MiddleInitial;
        STRING1   Gender;
        STRING42 Street;
        STRING20 City;
        STRING2   State;
        STRING5  Zip;
    END;
    EXPORT LogicalFile_Person := '~VISUALIZER::EXAMPLEDATA::People';
    EXPORT Dataset_Person := DATASET(LogicalFile_Person, Layout_Person, THOR);

    EXPORT Layout_Accounts := RECORD
        STRING20 Account;
        STRING8  OpenDate;
        STRING2   IndustryCode;
        STRING1   AcctType;
        STRING1   AcctRate;
        UNSIGNED1 Code1;
        UNSIGNED1 Code2;
        UNSIGNED4 HighCredit;
        UNSIGNED4 Balance;
    END;

END;
