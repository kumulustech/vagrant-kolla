# A Vagrantfile to deploy a multi-node OpenStack environment with Kolla

Vagrantfile supports only ubuntu and virtualbox at the moment

You can adjust the number of client nodes by changing the NUM_NODES
environment variable.

To launch the environment, just do:

  vagrant up

Once the system has launched, you should be able to verify
the OpenStack environment by the following:

  vagrant ssh control
  source openrc
  nova list

Examples for the KTOS-### class are in the example_files directory

======
 Copyright 2017 Kumulus Technologies
 Copyright 2017 Robert Starmer

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
