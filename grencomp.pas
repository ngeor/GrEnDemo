{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit GrEnComp;

{$warn 5023 off : no warning about unused units}
interface

uses
  GrEn, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('GrEn', @GrEn.Register);
end;

initialization
  RegisterPackage('GrEnComp', @Register);
end.
