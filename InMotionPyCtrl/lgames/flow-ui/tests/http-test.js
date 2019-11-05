//************************************** */
// http server test script
//************************************** */
const http = require('http');
const querystring = require("querystring");
//var o = require("ospec");

const API_HOST = 'localhost'
const API_PORT = 3000     //Server port number
var firstPatient = 'test' //id of patient to get
var firstProtocol= ''     //first protocol of protocol list
var usbDrive=''           //usb drive to copy to
var testNum= 1            //Test number
var newPatient = {        //Newly added patient
    id: 'jack',
    firstName: 'Jackie',
    lastName: 'Brown',
    birthDate: null,
    gender: 'F',
    dateOnset: null,
    impairmentSide: 'L',
    diagnosis: null,
    typeLocation: 'abc',
    otherImpairments: 'abc',
    precautions: null,
    positioningConsiderations: null
}

//Make http request to server
function makeRequest(url, method, pdata=0) {

    console.log('\n'+ testNum + `) ---- Testing Http ${method} for url: ${url}`)
    testNum++
    var qdata = querystring.stringify(pdata);

    return new Promise((resolve, reject) => {

        const options = {
            hostname: API_HOST,
            port: API_PORT,
            path: '/api' + url,
            method,
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(qdata)
              }
          }

          const req = http.request(options, (res) => {
            console.log('  ')
            if (res.statusCode == 200)
                   console.log("   ==> Success ........ Status=200")
            else if (res.statusCode == 500)
                   console.log("   ==> *Server Error* ... Status=500")
            else if (res.statusCode == 404)
                   console.log("   ==> *Not Found* ...... Status=404")
            else
                   console.log(`   ==> *Error* .... STATUS: ${res.statusCode}`)
            console.log('  ')
            //console.log(`HEADERS: ${JSON.stringify(res.headers)}`)

            // A chunk of data has been recieved.
            res.setEncoding('utf8');
            var data = ''
            res.on('data', (chunk) => { data += chunk; })
             // The whole response has been received. Print out the result.
            res.on('end', () => {
                resolve(data)
            })
          })  //http request

          req.on('error', (e) => {
            console.error(`problem with request: ${e.message}`)
          })

          if ( method != 'GET' && qdata != null ) {
                // write data to request body
                console.log("    (Posting Data:" + qdata+ ' )')
                req.write(qdata)
          }

          req.end()

        })  //promise
        .catch((Error) => {console.log(Error)})
}

//Test script to test the main functionality of server
function runTests() {

    /***** Robots ******/
            //Get list of robots
            makeRequest('/robots', 'GET').then(result => {
            console.log("@Request: Get list of robot")
            console.log("Response: " + result)
            const parsedData = JSON.parse(result)
            console.assert(Array.isArray(parsedData.robots))   //check if result is an array
        })
    .catch((Error) => {console.log(Error)})

    .then(() => {
            //Set Current Robot to planar
            const postData = {current_robot : "planar"}
            return makeRequest('/current-robot', 'POST', postData).then(result => {
            console.log("@Request: Set current robot to planar")
            const parsedData = JSON.parse(result)
            console.log("Response: ", parsedData)

         })
    .catch((Error) => {console.log(Error)})

    }).then(() => {
            //Get current robot
            return makeRequest('/current-robot', 'GET').then(result => {
            console.log("@Request: Get current robot")
            const parsedData = JSON.parse(result)
            console.log("Response: ", parsedData)

        })
    .catch((Error) => {console.log(Error)})

    }).then(() => {
            //Get current status of robot
            return makeRequest('/status', 'GET').then(result => {
            console.log("@Request: Get robot status")
            const parsedData = JSON.parse(result)
            console.log("Response: ", parsedData)

        })
    .catch((Error) => {console.log(Error)})

    /***** Protocols ******/
    }).then(() => {
            //get list of protocols
            return makeRequest('/protocols', 'GET').then(result => {
            console.log("@Request: Get list of protocols ")
            const parsedData = JSON.parse(result)
            firstProtocol = parsedData.protocols[0]
            console.assert(Array.isArray(parsedData.protocols))   //check if protocols result is an array
            console.log("Response: ", parsedData)

        })
    .catch((Error) => {console.log(Error)})

    }).then(() => {
            //Get therapies list for the first protocol
            return makeRequest('/therapies/'+ firstProtocol, 'GET').then(result => {
            console.log("@Request: Get list of therapies for " + firstProtocol)
            const parsedData = JSON.parse(result)
            console.log("Response: ", parsedData)

        })
    .catch((Error) => {console.log(Error)})

    }).then(() => {
            //Get evaluation list for the first protocol
            return makeRequest('/evaluations/'+ firstProtocol, 'GET').then(result => {
            console.log("@Request: Get list of evaluations for " + firstProtocol)
            const parsedData = JSON.parse(result)
            console.log("Response: ", parsedData)

         })
    .catch((Error) => {console.log(Error)})

    /***** Patients *******/
    }).then(() => {
        //Add new Patient
        const rnumber= Math.floor((Math.random() * 1000) + 1);
        newPatient.id = 'jack'+ rnumber
        return makeRequest('/patient', 'POST', newPatient ).then(result => {
        console.log("@Request: Add a new patient with firstname= Jackie and id= " + newPatient.id)
        const parsedData = JSON.parse(result)
        console.log("Response: ", parsedData)
    })
    .catch((Error) => {console.log(Error)})

    }).then(() => {
        //Update Patient information
        newPatient.firstName = 'Jack'
        newPatient.gender = 'M'
        return makeRequest('/patient', 'patch', newPatient).then(result => {
        console.log("@Request: update patient's firstName to Jack and gender to M for patient id= "+ newPatient.id)
        const parsedData = JSON.parse(result)
        console.log("Response: ", parsedData)

    })
    .catch((Error) => {console.log( Error)})

    }).then(() => {
        //get newly added patient info
        return makeRequest('/patient/'+ newPatient.id, 'GET').then(result => {
        console.log("@Request: Get patient info for " + newPatient.id )
        const parsedData = JSON.parse(result)
        console.log("Response: ", parsedData)

    })
    .catch((Error) => {console.log(Error)})

    }).then(() => {
        //get list of patient ids
        return makeRequest('/patientids', 'GET').then(result => {
        console.log("@Request: Get list of patient IDs")
        const parsedData = JSON.parse(result)
        console.assert(Array.isArray(parsedData.patients))   //check if result is an array
        console.log("Response: ", parsedData)

        //firstPatient= parsedData.patients[0]

    })
    .catch((Error) => {console.log(Error)})

    }).then(() => {
            //get list of patients
            return makeRequest('/patients', 'GET').then(result => {
            console.log("@Request: Get list of patients ")
            const parsedData = JSON.parse(result)
            console.assert(Array.isArray(parsedData.patients))      //check if result is an array
            console.log("Response: ", parsedData)

        })
    .catch((Error) => {console.log(Error)})

    /****** Reports *****/
    }).then(() => {
            //get report for patient
            return makeRequest('/report/'+ firstPatient, 'GET').then(result => {
            console.log("@Request: Get report for patient: "+ firstPatient)
            console.log("Response message length =", result.length)
            if (result.length < 200) // will only log result with a messages and not the actual report returned
                    console.log("message: ", result)
            //else  console.log("Report returned is too large to display")

        })
    .catch((Error) => {console.log(Error)})

    }).then(() => {
            //get session therapy history report
            return makeRequest('/report/therapy-history/'+ firstPatient, 'GET').then(result => {
            console.log("@Request: Get session therapy history for patient: " + firstPatient)
            const parsedData = JSON.parse(result)
            console.log("Response: ", parsedData)
            console.assert(Array.isArray(parsedData.sessions))

          })
    .catch((Error) => {console.log(Error)})
/*
    }).then(() => {
            //post start therapy session
            return makeRequest('/api/report/start-therapy-session/'+firstPatient, 'POST').then(result => {
            console.log("@Request: post start-therapy-session for patient: " + firstPatient)
            console.log("Response: ", result)

        })
    .catch((Error) => {console.log(Error)})
*/
    }).then(() => {
            //post adding of activity
             const postData =  {
                mode: "orientation",
                protocol: "adaptive10cm",
                activityType: "therapy",
                activity: "oneway_rec_1"
             }
            return makeRequest('/report/add-activity/'+firstPatient, 'POST', postData).then(result => {
            console.log("@Request: post adding of activity for patient: " + firstPatient)
            const parsedData = JSON.parse(result)
            console.log("Response: ", parsedData)

        })
    .catch((Error) => {console.log(Error)})

    /****** Media devices *****/
    }).then(() => {
            //get list of media devices
            return makeRequest('/media/devices', 'GET').then(result => {
            console.log("@Request: Get media devices list")
            const parsedData = JSON.parse(result)
            console.log("Response: ", parsedData)
            usbDrive=  parsedData.devices

        })
    .catch((Error) => {console.log(Error)})

    }).then(() => {
            // copy patient to USB
            const data = {
                patid: firstPatient,
                drive: usbDrive
            }
            return makeRequest('/media/copy-patient', 'POST',data).then(result => {
            console.log("@Request: copy patient data to USB drive for patient: " + firstPatient)
            const parsedData = JSON.parse(result)
            console.log("Response: ", parsedData)
        })
    .catch((Error) => {console.log(Error)})

    }).then(() => {
            // copy a patient report to USB
            const data = {
                patid: firstPatient,
                drive: usbDrive
            }
            return makeRequest('/media/copy-report', 'POST',data).then(result => {
            console.log("@Request: copy reports to USB drive for patient: " + firstPatient )
            const parsedData = JSON.parse(result)
            console.log("Response: ", parsedData)
        })
    .catch((Error) => {console.log(Error)})
    })
}

//Run all test
runTests()

