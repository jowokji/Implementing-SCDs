ALTER TABLE DimEmployee
DROP CONSTRAINT DimEmployee_pkey;

ALTER TABLE DimEmployee
ADD COLUMN StartDate TIMESTAMP,
ADD COLUMN EndDate TIMESTAMP,
ADD COLUMN IsCurrent BOOLEAN DEFAULT TRUE,
ADD COLUMN EmployeeHistoryID SERIAL PRIMARY KEY;

UPDATE DimEmployee
SET EmployeeHistoryID = DEFAULT;

UPDATE DimEmployee
SET StartDate = HireDate,
    EndDate = '9999-12-31';

CREATE OR REPLACE FUNCTION Employees_Update_Function()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.Title <> NEW.Title OR OLD.Address <> NEW.Address) AND OLD.IsCurrent AND NEW.IsCurrent THEN
        UPDATE DimEmployee
        SET EndDate = CURRENT_TIMESTAMP,
            IsCurrent = FALSE,
            Title = OLD.Title,
            Address = OLD.Address
        WHERE EmployeeID = OLD.EmployeeID AND IsCurrent = TRUE;

        INSERT INTO DimEmployee (EmployeeID, LastName, FirstName, Title, BirthDate, HireDate, Address, City, Region, PostalCode, Country, HomePhone, Extension, StartDate, EndDate, IsCurrent)
        VALUES (OLD.EmployeeID, OLD.LastName, OLD.FirstName, NEW.Title, OLD.BirthDate, OLD.HireDate, NEW.Address, OLD.City, OLD.Region, OLD.PostalCode, OLD.Country, OLD.HomePhone, OLD.Extension, CURRENT_TIMESTAMP, '9999-12-31', TRUE);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS Employees_Update_Trigger ON DimEmployee CASCADE;
CREATE TRIGGER Employees_Update_Trigger
AFTER UPDATE ON DimEmployee
FOR EACH ROW
EXECUTE FUNCTION Employees_Update_Function();

-- Checking what works
UPDATE DimEmployee
SET Address = 'Gomel'
WHERE FirstName = 'Uladzislau' AND LastName = 'Bandarenka' AND IsCurrent = TRUE;

UPDATE DimEmployee
SET Title = 'Manager'
WHERE FirstName = 'Mikita' AND LastName = 'Dubrovin' AND IsCurrent = TRUE;
