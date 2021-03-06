/**********************************************************************************************************************
 *  Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.                                           *
 *                                                                                                                    *
 *  Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance    *
 *  with the License. A copy of the License is located at                                                             *
 *                                                                                                                    *
 *      http://www.apache.org/licenses/LICNSE-2.0                                                                     *
 *                                                                                                                    *
 *  or in the 'license' file accompanying this file. This file is distributed on an 'AS IS' BASIS, WITHOUT WARRANTIES *
 *  OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions    *
 *  and limitations under the License.                                                                                *
 *********************************************************************************************************************/

import { SynthUtils } from '@aws-cdk/assert';
import { Stack, Aws } from '@aws-cdk/core';
import { Ingestion } from '../lib/ingestion/ingestion-construct';

test ('Event Bus creation', () => {
    const stack = new Stack();

    new Ingestion(stack, 'Ingestion', {
        stateMachineArn: 'stateMachineArn',
        solutionName: 'test-solution',
        ingestFrequency: '(0/2 * * * ? *)',
        supportedLang: 'de,en,es,it,pt,fr,ja,ko,hi,ar,zh-cn,zh-tw',
        queryParameter: 'Health',
        credentialKeyPath: '/some/dummy/path/test'
    });

    expect(SynthUtils.toCloudFormation(stack)).toMatchSnapshot();
});