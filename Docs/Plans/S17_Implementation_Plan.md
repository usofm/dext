# Implementation Plan - S17: Component-Based Design-Time Scaffolding

This plan outlines the steps to implement right-click scaffolding in the Delphi IDE for `TFDConnection` and `TDataSet`.

## Phase 1: IDE Registration & Component Editors
- **File:** `Sources/Design/Dext.EF.Design.Editors.pas`
- **Actions:**
    - Implement `TScaffoldingDataSetEditor` for `TDataSet`.
    - Implement `TScaffoldingConnectionEditor` for `TFDConnection` (FireDAC specific).
    - Update `RegisterEditors` to include these new registrations.
    - Add verbs:
        - `TDataSet`: "Dext: Create Entity from this Dataset..."
        - `TFDConnection`: "Dext: Scaffolding -> Generate Entities from Tables..."

## Phase 2: Metadata Extraction Helpers
- **File:** `Sources/Design/Dext.EF.Design.Scaffolding.Helpers.pas` (New file)
- **Actions:**
    - Create `TDataSetToMetaTable` helper: Converts `TField` collection and `TDataSet` properties into `TMetaTable`.
    - Create `TFDConnectionToMetaTable` helper: Uses FireDAC meta-info queries to extract schema info into `TMetaTable`.

## Phase 3: Scaffolding Preview UI
- **File:** `Sources/Design/Dext.EF.Design.Scaffolding.Preview.pas` (New VCL Form)
- **Actions:**
    - Simple VCL Form with:
        - `TMemo` (for code preview).
        - `TEdit` + `TButton` (for target path).
        - `TCheckBox` (Smart Types vs POCO).
        - `TButton` (Generate/Create Unit).
        - `TButton` (Cancel).

## Phase 4: Integration with Core Engine
- **Logic:**
    - Use `TScaffoldingMetadataProcessor` to process `TMetaTable`.
    - Use `TTemplatedEntityGenerator` (from `Dext.Entity.TemplatedScaffolding.pas`) to render the code.
    - Template selection: Use default Dext templates.

## Phase 5: IDE Unit Creation (IOTA)
- **Actions:**
    - Use `IOTAModuleServices.CreateModule` to open a new unnamed unit in the IDE.
    - Insert the generated code into the new unit buffer.
    - Suggest saving to the owner project's directory.

## Phase 6: Table Selection Dialog (FireDAC)
- **Actions:**
    - Create a simple checklist dialog to select tables from a `TFDConnection`.
