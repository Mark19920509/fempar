#################################################################
# Serial tests
#################################################################

IF(MPI_FOUND)

    # Search all files and directories in the top directory
    FILE(GLOB DIRECTORIES *)

    # Loop over all files/Directories
    FOREACH( DIR ${DIRECTORIES})
        # search all files mathing the Regex in the DIRectory
        FILE(GLOB TESTS_SERIAL_SRC ${DIR}/*.f90 ${DIR}/*.F90)

        # Loop over all files in this directory.
        # All files in the top directory (DIR) are executable targets
        FOREACH(TEST_SRC ${TESTS_SERIAL_SRC})
            # Use the filename without extension as the name of the executable target
            GET_FILENAME_COMPONENT(EXE_NAME ${TEST_SRC} NAME_WE)
            SET(CMAKE_Fortran_MODULE_DIRECTORY ${TESTS_OUTPUT_PATH}/modules/${EXE_NAME})
            SET(${EXE_NAME}_MODULES_DIR "${DIR}/modules")
            UNSET(${EXE_NAME}_MODULES_SRC)
            IF(IS_DIRECTORY ${${EXE_NAME}_MODULES_DIR})
                # Search module files to add to the current target
                FILE(GLOB ${EXE_NAME}_MODULES_SRC ${${EXE_NAME}_MODULES_DIR}/*.f90 ${${EXE_NAME}_MODULES_DIR}/*.F90)
            ENDIF()
            # Create the current executable target
            ADD_EXECUTABLE(${EXE_NAME} ${TEST_SRC} ${${EXE_NAME}_MODULES_SRC}) 
            # Link the current target with Fempar
            TARGET_LINK_LIBRARIES(${EXE_NAME} ${PROJECT_NAME})
            # Link the current target with MPI libraries
            TARGET_LINK_LIBRARIES(${EXE_NAME} ${MPI_Fortran_LIBRARIES})
            # Link the current target with external projects and libraries
            TARGET_LINK_LIBRARIES(${EXE_NAME} ${${PROJECT_NAME}_EXTERNAL_LIBRARIES} ${${PROJECT_NAME}_EXTERNAL_PROJECTS})
            IF(EXISTS ${SCRIPTS_OUTPUT_PATH}/${EXE_NAME})
                # If there is an script with the name of the executable, add the current target to the Cmake-CTest system
                ADD_TEST(${EXE_NAME}_TEST ${SCRIPTS_OUTPUT_PATH}/${EXE_NAME} ${EXECUTABLE_OUTPUT_PATH}/${EXE_NAME} ${DATA_OUTPUT_PATH}/${EXE_NAME} ${SCRIPTS_OUTPUT_PATH})
                SET_TESTS_PROPERTIES( ${EXE_NAME}_TEST PROPERTIES LABELS "SERIAL" )
            ENDIF()
            IF(EXISTS ${SCRIPTS_OUTPUT_PATH}/${EXE_NAME}_fast)
                # If there is an script with the name of the executable_quickly, add the current target to the Cmake-CTest system
                ADD_TEST(${EXE_NAME}_TEST_fast ${SCRIPTS_OUTPUT_PATH}/${EXE_NAME}_fast ${EXECUTABLE_OUTPUT_PATH}/${EXE_NAME} ${DATA_OUTPUT_PATH}/${EXE_NAME} ${SCRIPTS_OUTPUT_PATH})
                SET_TESTS_PROPERTIES( ${EXE_NAME}_TEST_fast PROPERTIES LABELS "SERIAL_FAST")
            ENDIF()
        ENDFOREACH()
    ENDFOREACH()

ENDIF()



