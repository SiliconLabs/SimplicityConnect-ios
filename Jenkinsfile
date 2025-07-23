pipeline {
     agent {
     node{
             label 'mac'
         }
     }
 environment {
         LANG = "en_US.UTF-8"
         LC_ALL = "en_US.UTF-8"
         MY_VAR = 'NULL'
     }

    stages {
         stage("Install gems") {
             steps {
                 sh 'bundle install'
                 sh 'bundle update fastlane'
                 sh 'pod install'
             }
         }

         stage("Build app") {
             steps {
                 script {
                     // Example build step

                     def result = sh(script: 'fastlane build_app_for_simulator', returnStatus: true)
                     if (result != 0) {
                         currentBuild.result = 'FAILURE'
                         error("Build failed")
                     } else {
                         echo 'Build generated successfully'
                         MY_VAR = 'SUCCESS'
                         echo "Workspace path is: ${env.WORKSPACE}"
                     }
                 }
             }
         }

         stage("ipa launch"){
             steps{
                 script{
                     if(MY_VAR == 'SUCCESS'){
                         echo 'stage APK launch'
                         def result = sh(script: './launch_ipa.sh',returnStatus: true)
                         if(result != 0){
                             echo 'stage 2 failure check console output/shell output'
                         }
                         else{
                             echo 'Application launched successfully'
                             currentBuild.result = 'SUCCESS'
                         }
                     }
                 }
             }
         }

         stage('Hardware Flash'){
             steps{
                 script{
                     if(MY_VAR == 'SUCCESS'){
                         echo 'stage hardware flash'
                         withEnv(['PATH+EXTRA=/Users/jenkins/Desktop/SimplicityCommander-Mac/Commander-cli.app/Contents/MacOS']){
                         def result = sh(script: './hardware_flash.sh',returnStatus: true)
                         if(result != 0){
                             echo 'stage 3 failure check console output/shell output'
                             MY_VAR = 'FAIL'
                         }
                         else{
                             echo 'Firmware for connected Hardware Flashed successfully'
                             currentBuild.result = 'SUCCESS'
                             MY_VAR = 'SUCCESS'
                         }
                     }
                 }
             }
         }

     }

     stage('Appium Test Start'){
             steps{
                 script{
                     if(MY_VAR == 'SUCCESS'){
                         def result = sh(script: './start_test.sh',returnStatus: true)
                         if(result != 0){
                             echo 'stage 4 failure check console output/shell output'
                             MY_VAR = 'FAIL'
                         }
                         else{
                             echo 'Application testing started successfully'
                             currentBuild.result = 'SUCCESS'
                             MY_VAR = 'SUCCESS'
                         }
                     }
                 }
             }
         }
 }
 }
