!> \file
!> \author Chris Bradley
!> \brief This is an example program to solve a Laplace equation using OpenCMISS calls.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is OpenCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s):
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> \example ClassicalField/Laplace/42Master/src/42MasterExample.f90
!! Example program to solve a Laplace equation using OpenCMISS calls.
!! \htmlinclude ClassicalField/Laplace/42Master/history.html
!<

!> Main program

PROGRAM LAPLACEEXAMPLE

  USE OPENCMISS
  USE MPI


#ifdef WIN32
  USE IFQWIN
#endif

  IMPLICIT NONE

  !Test program parameters

  REAL(CMISSDP), PARAMETER :: HEIGHT=1.0_CMISSDP
  REAL(CMISSDP), PARAMETER :: WIDTH=2.0_CMISSDP
  REAL(CMISSDP), PARAMETER :: LENGTH=3.0_CMISSDP

  LOGICAL, PARAMETER :: SOLVER_DIRECT_TYPE=.TRUE.

  INTEGER(CMISSIntg), PARAMETER :: CoordinateSystemUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: RegionUserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: BasisUserNumber=3
  INTEGER(CMISSIntg), PARAMETER :: GeneratedMeshUserNumber=4
  INTEGER(CMISSIntg), PARAMETER :: MeshUserNumber=5
  INTEGER(CMISSIntg), PARAMETER :: DecompositionUserNumber=6
  INTEGER(CMISSIntg), PARAMETER :: GeometricFieldUserNumber=7
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetFieldUserNumber=8
  INTEGER(CMISSIntg), PARAMETER :: DependentFieldUserNumber=9
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetUserNumber=10
  INTEGER(CMISSIntg), PARAMETER :: ProblemUserNumber=11

  !Program types

  !Program variables

  INTEGER(CMISSIntg) :: NUMBER_OF_ARGUMENTS
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_X_ELEMENTS = -1
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_Y_ELEMENTS = -1
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_Z_ELEMENTS = -1
  INTEGER(CMISSIntg) :: INTERPOLATION_TYPE
  INTEGER(CMISSIntg) :: NUMBER_OF_GAUSS_XI
  INTEGER(CMISSIntg) :: I
  CHARACTER(LEN=255) :: COMMAND_ARGUMENT,Filename
  CHARACTER(LEN=255) :: BUFFER

  LOGICAL :: OPTION_1D   = .FALSE.
  LOGICAL :: OPTION_2D   = .FALSE.
  LOGICAL :: OPTION_3D   = .FALSE.
  LOGICAL :: OPTION_TRI  = .FALSE.
  LOGICAL :: OPTION_TET  = .FALSE.
  LOGICAL :: OPTION_QUAD = .FALSE.
  LOGICAL :: OPTION_HEX  = .FALSE.
  LOGICAL :: OPTION_HERMITE        = .FALSE.
  LOGICAL :: OPTION_LINEARBASIS    = .FALSE.
  LOGICAL :: OPTION_QUADRATICBASIS = .FALSE.
  LOGICAL :: OPTION_CUBICBASIS     = .FALSE.


  !CMISS variables

  TYPE(CMISSBasisType) :: Basis
  TYPE(CMISSBoundaryConditionsType) :: BoundaryConditions
  TYPE(CMISSCoordinateSystemType) :: CoordinateSystem,WorldCoordinateSystem
  TYPE(CMISSDecompositionType) :: Decomposition
  TYPE(CMISSEquationsType) :: Equations
  TYPE(CMISSEquationsSetType) :: EquationsSet
  TYPE(CMISSFieldType) :: GeometricField,EquationsSetField,DependentField
  TYPE(CMISSFieldsType) :: Fields
  TYPE(CMISSGeneratedMeshType) :: GeneratedMesh
  TYPE(CMISSMeshType) :: Mesh
  TYPE(CMISSNodesType) :: Nodes
  TYPE(CMISSProblemType) :: Problem
  TYPE(CMISSRegionType) :: Region,WorldRegion
  TYPE(CMISSSolverType) :: Solver
  TYPE(CMISSSolverEquationsType) :: SolverEquations

#ifdef WIN32
  !Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif

  !Generic CMISS variables

  INTEGER(CMISSIntg) :: NumberOfComputationalNodes,ComputationalNodeNumber
  INTEGER(CMISSIntg) :: EquationsSetIndex
  INTEGER(CMISSIntg) :: FirstNodeNumber,LastNodeNumber
  INTEGER(CMISSIntg) :: FirstNodeDomain,LastNodeDomain
  INTEGER(CMISSIntg) :: Err

#ifdef WIN32
  !Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="General Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  !Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  !If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif

  !Get command line arguments
  I = 1
  NUMBER_OF_ARGUMENTS = COMMAND_ARGUMENT_COUNT()
  DO WHILE (I <= NUMBER_OF_ARGUMENTS)
    CALL GET_COMMAND_ARGUMENT(I,COMMAND_ARGUMENT)
    SELECT CASE(COMMAND_ARGUMENT)
      CASE('-1D')
        OPTION_1D = .TRUE.
      CASE('-2D')
        OPTION_2D = .TRUE.
      CASE('-3D')
        OPTION_3D = .TRUE.
      CASE('-tri')
        OPTION_TRI = .TRUE.
      CASE('-tet')
        OPTION_TET = .TRUE.
      CASE('-quad')
        OPTION_QUAD = .TRUE.
      CASE('-hex')
        OPTION_HEX = .TRUE.
      CASE('-linearbasis')
        OPTION_LINEARBASIS = .TRUE.
      CASE('-quadraticbasis')
        OPTION_QUADRATICBASIS = .TRUE.
      CASE('-cubicbasis')
        OPTION_CUBICBASIS = .TRUE.
      CASE('-hermite')
        OPTION_HERMITE = .TRUE.
      CASE('-nx')
        CALL GET_COMMAND_ARGUMENT(I+1,BUFFER)
        READ (BUFFER,*) NUMBER_GLOBAL_X_ELEMENTS
        I = I + 1
      CASE('-ny')
        CALL GET_COMMAND_ARGUMENT(I+1,BUFFER)
        READ (BUFFER,*) NUMBER_GLOBAL_Y_ELEMENTS
        I = I + 1
      CASE('-nz')
        CALL GET_COMMAND_ARGUMENT(I+1,BUFFER)
        READ (BUFFER,*) NUMBER_GLOBAL_Z_ELEMENTS
        I = I + 1
      CASE DEFAULT
        WRITE(*,*) 'Unknown argument: ', COMMAND_ARGUMENT
      END SELECT
      I = I + 1
  ENDDO

  !Check for nonsensical arguemnts
  !TODO
  IF (.NOT.(OPTION_3D .OR. OPTION_2D .OR. OPTION_1D)) THEN
    CALL PRINT_USAGE_AND_DIE('Must specify the dimensionality')
  ENDIF

  !option_hermite indicates quad or hex elements
  IF (.NOT.(OPTION_TRI .OR. OPTION_TET .OR. OPTION_QUAD .OR. OPTION_HEX .OR. OPTION_HERMITE .OR. OPTION_1D)) THEN
    CALL PRINT_USAGE_AND_DIE('Must specify the element type')
  ENDIF

  IF (.NOT.(OPTION_LINEARBASIS .OR. OPTION_QUADRATICBASIS .OR. OPTION_CUBICBASIS .OR. OPTION_HERMITE)) THEN
    CALL PRINT_USAGE_AND_DIE('Must specify the basis type')
  ENDIF

  IF (NUMBER_GLOBAL_X_ELEMENTS < 1 .OR. ((OPTION_2D .OR. OPTION_3D) .AND. NUMBER_GLOBAL_Y_ELEMENTS < 1) .OR.  &
      & (OPTION_3D .AND. NUMBER_GLOBAL_Z_ELEMENTS < 0)) THEN
    CALL PRINT_USAGE_AND_DIE('Must specify number of elements')
  ENDIF

  !Interpret arguments

  IF(OPTION_1D) THEN
    NUMBER_GLOBAL_Y_ELEMENTS = 0
    NUMBER_GLOBAL_Z_ELEMENTS = 0
  ELSEIF(OPTION_2D) THEN
    NUMBER_GLOBAL_Z_ELEMENTS = 0
  ENDIF

  NUMBER_OF_GAUSS_XI=0
  IF(OPTION_LINEARBASIS) THEN
    IF(OPTION_TRI .OR. OPTION_TET) THEN
      INTERPOLATION_TYPE = 7
    ELSE
      INTERPOLATION_TYPE = 1
      NUMBER_OF_GAUSS_XI=2
    ENDIF
  ELSEIF(OPTION_QUADRATICBASIS) THEN
    IF(OPTION_TRI .OR. OPTION_TET) THEN
      INTERPOLATION_TYPE = 8
    ELSE
      INTERPOLATION_TYPE = 2
      NUMBER_OF_GAUSS_XI=3
    ENDIF
  ELSEIF(OPTION_HERMITE) THEN
    INTERPOLATION_TYPE = 4
    NUMBER_OF_GAUSS_XI=4
  ELSEIF(OPTION_CUBICBASIS) THEN
    IF(OPTION_TRI .OR. OPTION_TET) THEN
      INTERPOLATION_TYPE = 9
    ELSE
      INTERPOLATION_TYPE = 3
      NUMBER_OF_GAUSS_XI=4
    ENDIF
  ELSE
    CALL HANDLE_ERROR("Could not set interploation type")
  ENDIF


  !Intialise OpenCMISS
  CALL CMISSInitialise(WorldCoordinateSystem,WorldRegion,Err)

  CALL CMISSErrorHandlingModeSet(CMISS_ERRORS_TRAP_ERROR,Err)

  WRITE(Filename,'(A,"_",I0,"x",I0,"x",I0,"_",I0)') "Laplace",NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS, &
    & NUMBER_GLOBAL_Z_ELEMENTS,INTERPOLATION_TYPE

  CALL CMISSOutputSetOn(Filename,Err)

  !Get the computational nodes information
  CALL CMISSComputationalNumberOfNodesGet(NumberOfComputationalNodes,Err)
  CALL CMISSComputationalNodeNumberGet(ComputationalNodeNumber,Err)

  !Start the creation of a new RC coordinate system
  CALL CMISSCoordinateSystem_Initialise(CoordinateSystem,Err)
  CALL CMISSCoordinateSystem_CreateStart(CoordinateSystemUserNumber,CoordinateSystem,Err)
  IF(OPTION_1D) THEN
    !Set the coordinate system to be 1D
    CALL CMISSCoordinateSystem_DimensionSet(CoordinateSystem,1,Err)
  ELSEIF(OPTION_2D) THEN
    !Set the coordinate system to be 2D
    CALL CMISSCoordinateSystem_DimensionSet(CoordinateSystem,2,Err)
  ELSE
    !Set the coordinate system to be 3D
    CALL CMISSCoordinateSystem_DimensionSet(CoordinateSystem,3,Err)
  ENDIF
  !Finish the creation of the coordinate system
  CALL CMISSCoordinateSystem_CreateFinish(CoordinateSystem,Err)

  !Start the creation of the region
  CALL CMISSRegion_Initialise(Region,Err)
  CALL CMISSRegion_CreateStart(RegionUserNumber,WorldRegion,Region,Err)
  CALL CMISSRegion_LabelSet(Region,"LaplaceRegion",Err)
  !Set the regions coordinate system to the 2D RC coordinate system that we have created
  CALL CMISSRegion_CoordinateSystemSet(Region,CoordinateSystem,Err)
  !Finish the creation of the region
  CALL CMISSRegion_CreateFinish(Region,Err)

  !Start the creation of a basis (default is trilinear lagrange)
  CALL CMISSBasis_Initialise(Basis,Err)
  CALL CMISSBasis_CreateStart(BasisUserNumber,Basis,Err)
  IF(OPTION_TRI .OR. OPTION_TET) THEN !Default is Lagrange Hermite type
    CALL CMISSBasis_TypeSet(Basis,CMISS_BASIS_SIMPLEX_TYPE,Err)
  ENDIF
  IF(OPTION_1D) THEN
    !Set the basis to be a linear Lagrange basis
    CALL CMISSBasis_NumberOfXiSet(Basis,1,Err)
    CALL CMISSBasis_InterpolationXiSet(Basis,[INTERPOLATION_TYPE],Err)
    IF(.NOT. OPTION_TRI .AND. .NOT. OPTION_TET) THEN
      CALL CMISSBasis_QuadratureNumberOfGaussXiSet(Basis,[NUMBER_OF_GAUSS_XI],Err)
    ENDIF
  ELSEIF(OPTION_2D) THEN
    !Set the basis to be a bilinear Lagrange basis
    CALL CMISSBasis_NumberOfXiSet(Basis,2,Err)
    CALL CMISSBasis_InterpolationXiSet(Basis,[INTERPOLATION_TYPE,INTERPOLATION_TYPE],Err)
    IF(.NOT. OPTION_TRI .AND. .NOT. OPTION_TET) THEN
      CALL CMISSBasis_QuadratureNumberOfGaussXiSet(Basis,[NUMBER_OF_GAUSS_XI,NUMBER_OF_GAUSS_XI],Err)
    ENDIF
  ELSE
    !Set the basis to be a trilinear Lagrange basis
    CALL CMISSBasis_NumberOfXiSet(Basis,3,Err)
    CALL CMISSBasis_InterpolationXiSet(Basis,[INTERPOLATION_TYPE,INTERPOLATION_TYPE,INTERPOLATION_TYPE],Err)
    IF(.NOT. OPTION_TRI .AND. .NOT. OPTION_TET) THEN
      CALL CMISSBasis_QuadratureNumberOfGaussXiSet(Basis,[NUMBER_OF_GAUSS_XI,NUMBER_OF_GAUSS_XI,NUMBER_OF_GAUSS_XI],Err)
    ENDIF
  ENDIF
  !Finish the creation of the basis
  CALL CMISSBasis_CreateFinish(Basis,Err)

  !Start the creation of a generated mesh in the region
  CALL CMISSGeneratedMesh_Initialise(GeneratedMesh,Err)
  CALL CMISSGeneratedMesh_CreateStart(GeneratedMeshUserNumber,Region,GeneratedMesh,Err)
  !Set up a regular x*y*z mesh
  CALL CMISSGeneratedMesh_TypeSet(GeneratedMesh,CMISS_GENERATED_MESH_REGULAR_MESH_TYPE,Err)
  !Set the default basis
  CALL CMISSGeneratedMesh_BasisSet(GeneratedMesh,Basis,Err)
  !Define the mesh on the region
  IF(OPTION_1D) THEN
    CALL CMISSGeneratedMesh_ExtentSet(GeneratedMesh,[WIDTH],Err)
    CALL CMISSGeneratedMesh_NumberOfElementsSet(GeneratedMesh,[NUMBER_GLOBAL_X_ELEMENTS],Err)
  ELSEIF(OPTION_2D) THEN
    CALL CMISSGeneratedMesh_ExtentSet(GeneratedMesh,[WIDTH,HEIGHT],Err)
    CALL CMISSGeneratedMesh_NumberOfElementsSet(GeneratedMesh,[NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS],Err)
  ELSE
    CALL CMISSGeneratedMesh_ExtentSet(GeneratedMesh,[WIDTH,HEIGHT,LENGTH],Err)
    CALL CMISSGeneratedMesh_NumberOfElementsSet(GeneratedMesh,[NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS, &
      & NUMBER_GLOBAL_Z_ELEMENTS],Err)
  ENDIF
  !Finish the creation of a generated mesh in the region
  CALL CMISSMesh_Initialise(Mesh,Err)
  CALL CMISSGeneratedMesh_CreateFinish(GeneratedMesh,MeshUserNumber,Mesh,Err)

  !Create a decomposition
  CALL CMISSDecomposition_Initialise(Decomposition,Err)
  CALL CMISSDecomposition_CreateStart(DecompositionUserNumber,Mesh,Decomposition,Err)
  !Set the decomposition to be a general decomposition with the specified number of domains
  CALL CMISSDecomposition_TypeSet(Decomposition,CMISS_DECOMPOSITION_CALCULATED_TYPE,Err)
  CALL CMISSDecomposition_NumberOfDomainsSet(Decomposition,NumberOfComputationalNodes,Err)
  !Finish the decomposition
  CALL CMISSDecomposition_CreateFinish(Decomposition,Err)

  !Start to create a default (geometric) field on the region
  CALL CMISSField_Initialise(GeometricField,Err)
  CALL CMISSField_CreateStart(GeometricFieldUserNumber,Region,GeometricField,Err)
  !Set the decomposition to use
  CALL CMISSField_MeshDecompositionSet(GeometricField,Decomposition,Err)
  !Set the domain to be used by the field components.
  CALL CMISSField_ComponentMeshComponentSet(GeometricField,CMISS_FIELD_U_VARIABLE_TYPE,1,1,Err)
  IF(NUMBER_GLOBAL_Y_ELEMENTS/=0) THEN
    CALL CMISSField_ComponentMeshComponentSet(GeometricField,CMISS_FIELD_U_VARIABLE_TYPE,2,1,Err)
  ENDIF
  IF(NUMBER_GLOBAL_Z_ELEMENTS/=0) THEN
    CALL CMISSField_ComponentMeshComponentSet(GeometricField,CMISS_FIELD_U_VARIABLE_TYPE,3,1,Err)
  ENDIF
  !Finish creating the field
  CALL CMISSField_CreateFinish(GeometricField,Err)

  !Update the geometric field parameters
  CALL CMISSGeneratedMesh_GeometricParametersCalculate(GeometricField,GeneratedMesh,Err)

  !Create the Standard Laplace Equations set
  CALL CMISSEquationsSet_Initialise(EquationsSet,Err)
  CALL CMISSField_Initialise(EquationsSetField,Err)
  CALL CMISSEquationsSet_CreateStart(EquationsSetUserNumber,Region,GeometricField,CMISS_EQUATIONS_SET_CLASSICAL_FIELD_CLASS, &
    & CMISS_EQUATIONS_SET_LAPLACE_EQUATION_TYPE,CMISS_EQUATIONS_SET_STANDARD_LAPLACE_SUBTYPE,EquationsSetFieldUserNumber, &
    & EquationsSetField,EquationsSet,Err)
  !Finish creating the equations set
  CALL CMISSEquationsSet_CreateFinish(EquationsSet,Err)

  !Create the equations set dependent field variables
  CALL CMISSField_Initialise(DependentField,Err)
  CALL CMISSEquationsSet_DependentCreateStart(EquationsSet,DependentFieldUserNumber,DependentField,Err)
  !Set the DOFs to be contiguous across components
  CALL CMISSField_DOFOrderTypeSet(DependentField,CMISS_FIELD_U_VARIABLE_TYPE,CMISS_FIELD_CONTIGUOUS_COMPONENT_DOF_ORDER,Err)
  CALL CMISSField_DOFOrderTypeSet(DependentField,CMISS_FIELD_DELUDELN_VARIABLE_TYPE,CMISS_FIELD_CONTIGUOUS_COMPONENT_DOF_ORDER,Err)
  !Finish the equations set dependent field variables
  CALL CMISSEquationsSet_DependentCreateFinish(EquationsSet,Err)

  !Initialise the field with an initial guess
  IF(.NOT. SOLVER_DIRECT_TYPE) THEN
    CALL CMISSField_ComponentValuesInitialise(DependentField,CMISS_FIELD_U_VARIABLE_TYPE,CMISS_FIELD_VALUES_SET_TYPE,1, &
      & 0.5_CMISSDP, &
      & Err)
  ENDIF

  !Create the equations set equations
  CALL CMISSEquations_Initialise(Equations,Err)
  CALL CMISSEquationsSet_EquationsCreateStart(EquationsSet,Equations,Err)
  !Set the equations matrices sparsity type
  CALL CMISSEquations_SparsityTypeSet(Equations,CMISS_EQUATIONS_SPARSE_MATRICES,Err)
  !CALL CMISSEquations_SparsityTypeSet(Equations,CMISS_EQUATIONS_FULL_MATRICES,Err)
  !Set the equations set output
  CALL CMISSEquations_OutputTypeSet(Equations,CMISS_EQUATIONS_NO_OUTPUT,Err)
  !CALL CMISSEquations_OutputTypeSet(Equations,CMISS_EQUATIONS_TIMING_OUTPUT,Err)
  !CALL CMISSEquations_OutputTypeSet(Equations,CMISS_EQUATIONS_MATRIX_OUTPUT,Err)
  !CALL CMISSEquations_OutputTypeSet(Equations,CMISS_EQUATIONS_ELEMENT_MATRIX_OUTPUT,Err)
  !Finish the equations set equations
  CALL CMISSEquationsSet_EquationsCreateFinish(EquationsSet,Err)

  !Start the creation of a problem.
  CALL CMISSProblem_Initialise(Problem,Err)
  CALL CMISSProblem_CreateStart(ProblemUserNumber,Problem,Err)
  !Set the problem to be a standard Laplace problem
  CALL CMISSProblem_SpecificationSet(Problem,CMISS_PROBLEM_CLASSICAL_FIELD_CLASS,CMISS_PROBLEM_LAPLACE_EQUATION_TYPE, &
    & CMISS_PROBLEM_STANDARD_LAPLACE_SUBTYPE,Err)
  !Finish the creation of a problem.
  CALL CMISSProblem_CreateFinish(Problem,Err)

  !Start the creation of the problem control loop
  CALL CMISSProblem_ControlLoopCreateStart(Problem,Err)
  !Finish creating the problem control loop
  CALL CMISSProblem_ControlLoopCreateFinish(Problem,Err)

  !Start the creation of the problem solvers
  CALL CMISSSolver_Initialise(Solver,Err)
  CALL CMISSProblem_SolversCreateStart(Problem,Err)
  CALL CMISSProblem_SolverGet(Problem,CMISS_CONTROL_LOOP_NODE,1,Solver,Err)
  !CALL CMISSSolver_OutputTypeSet(Solver,CMISS_SOLVER_NO_OUTPUT,Err)
  !CALL CMISSSolver_OutputTypeSet(Solver,CMISS_SOLVER_PROGRESS_OUTPUT,Err)
  !CALL CMISSSolver_OutputTypeSet(Solver,CMISS_SOLVER_TIMING_OUTPUT,Err)
  CALL CMISSSolver_OutputTypeSet(Solver,CMISS_SOLVER_SOLVER_OUTPUT,Err)
  !CALL CMISSSolver_OutputTypeSet(Solver,CMISS_SOLVER_MATRIX_OUTPUT,Err)
  IF(SOLVER_DIRECT_TYPE) THEN
    CALL CMISSSolver_LinearTypeSet(Solver,CMISS_SOLVER_LINEAR_DIRECT_SOLVE_TYPE,Err)
    CALL CMISSSolver_LibraryTypeSet(Solver,CMISS_SOLVER_MUMPS_LIBRARY,Err)
    !CALL CMISSSolver_LibraryTypeSet(Solver,CMISS_SOLVER_SUPERLU_LIBRARY,Err)
    !CALL CMISSSolver_LibraryTypeSet(Solver,CMISS_SOLVER_PASTIX_LIBRARY,Err)
  ELSE
    CALL CMISSSolver_LinearTypeSet(Solver,CMISS_SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE,Err)
    CALL CMISSSolver_LinearIterativeAbsoluteToleranceSet(Solver,1.0E-10_CMISSDP,Err)
    CALL CMISSSolver_LinearIterativeRelativeToleranceSet(Solver,1.0E-10_CMISSDP,Err)
    CALL CMISSSolver_LinearIterativeMaximumIterationsSet(Solver,100000,Err)
  ENDIF
  !Finish the creation of the problem solver
  CALL CMISSProblem_SolversCreateFinish(Problem,Err)

  !Start the creation of the problem solver equations
  CALL CMISSSolver_Initialise(Solver,Err)
  CALL CMISSSolverEquations_Initialise(SolverEquations,Err)
  CALL CMISSProblem_SolverEquationsCreateStart(Problem,Err)
  !Get the solve equations
  CALL CMISSProblem_SolverGet(Problem,CMISS_CONTROL_LOOP_NODE,1,Solver,Err)
  CALL CMISSSolver_SolverEquationsGet(Solver,SolverEquations,Err)
  !Set the solver equations sparsity
  CALL CMISSSolverEquations_SparsityTypeSet(SolverEquations,CMISS_SOLVER_SPARSE_MATRICES,Err)
  !CALL CMISSSolverEquations_SparsityTypeSet(SolverEquations,CMISS_SOLVER_FULL_MATRICES,Err)
  !Add in the equations set
  CALL CMISSSolverEquations_EquationsSetAdd(SolverEquations,EquationsSet,EquationsSetIndex,Err)
  !Finish the creation of the problem solver equations
  CALL CMISSProblem_SolverEquationsCreateFinish(Problem,Err)

  !Start the creation of the equations set boundary conditions
  CALL CMISSBoundaryConditions_Initialise(BoundaryConditions,Err)
  CALL CMISSSolverEquations_BoundaryConditionsCreateStart(SolverEquations,BoundaryConditions,Err)
  !Set the first node to 0.0 and the last node to 1.0
  FirstNodeNumber=1
  CALL CMISSNodes_Initialise(Nodes,Err)
  CALL CMISSRegion_NodesGet(Region,Nodes,Err)
  CALL CMISSNodes_NumberOfNodesGet(Nodes,LastNodeNumber,Err)
  CALL CMISSDecomposition_NodeDomainGet(Decomposition,FirstNodeNumber,1,FirstNodeDomain,Err)
  CALL CMISSDecomposition_NodeDomainGet(Decomposition,LastNodeNumber,1,LastNodeDomain,Err)
  IF(FirstNodeDomain==ComputationalNodeNumber) THEN
    CALL CMISSBoundaryConditions_SetNode(BoundaryConditions,DependentField,CMISS_FIELD_U_VARIABLE_TYPE,1,1,FirstNodeNumber,1, &
      & CMISS_BOUNDARY_CONDITION_FIXED,0.0_CMISSDP,Err)
  ENDIF
  IF(LastNodeDomain==ComputationalNodeNumber) THEN
    CALL CMISSBoundaryConditions_SetNode(BoundaryConditions,DependentField,CMISS_FIELD_U_VARIABLE_TYPE,1,1,LastNodeNumber,1, &
      & CMISS_BOUNDARY_CONDITION_FIXED,1.0_CMISSDP,Err)
  ENDIF
  !Finish the creation of the equations set boundary conditions
  CALL CMISSSolverEquations_BoundaryConditionsCreateFinish(SolverEquations,Err)

  !Solve the problem
  CALL CMISSProblem_Solve(Problem,Err)

  !Export results
  CALL CMISSFields_Initialise(Fields,Err)
  CALL CMISSFields_Create(Region,Fields,Err)
  CALL CMISSFields_NodesExport(Fields,"Laplace","FORTRAN",Err)
  CALL CMISSFields_ElementsExport(Fields,"Laplace","FORTRAN",Err)
  CALL CMISSFields_Finalise(Fields,Err)

  !Finialise CMISS
  CALL CMISSFinalise(Err)

  WRITE(*,'(A)') "Program successfully completed."

  STOP

CONTAINS

  SUBROUTINE HANDLE_ERROR(ERROR_STRING)

    CHARACTER(LEN=*), INTENT(IN) :: ERROR_STRING

    WRITE(*,'(">>ERROR: ",A)') ERROR_STRING(1:LEN_TRIM(ERROR_STRING))
    STOP

  END SUBROUTINE HANDLE_ERROR

  SUBROUTINE PRINT_USAGE_AND_DIE(ERROR_STRING)
    CHARACTER(LEN=*), INTENT(IN) :: ERROR_STRING

    WRITE (*,*) ERROR_STRING
    WRITE (*,*) ''
    WRITE (*,*) 'Usage:'
    WRITE (*,*) 'The options fall into the following groups:'
    WRITE (*,*) '([*] indicates the default option)'
    WRITE (*,*) 'Dimension:    -1D/-2D/-3D                              [2D]'
    WRITE (*,*) 'Element Type: -tri/-tet/-quad/-hex/-hermite            [quad/hex]'
    WRITE (*,*) 'Basis Type:   -linearbasis/-quadraticbasis/-cubicbasis [linearbasis]'

    WRITE (*,*) ''
    WRITE (*,*) 'Furthermore, the user must specify the number of elements in each '
    WRITE (*,*) 'dimension, for the appropriate number of dimensions. The format is:'
    !WRITE (*,*) ''
    WRITE (*,*) '-nx # -ny # -nz #'

    CALL EXIT(1)

  END SUBROUTINE PRINT_USAGE_AND_DIE

END PROGRAM LAPLACEEXAMPLE
