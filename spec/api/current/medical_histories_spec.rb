require 'swagger_helper'

describe 'Medical History Current API', swagger_doc: 'current/swagger.json' do
  path '/medical_histories/sync' do

    post 'Syncs medical_history data from device to server.' do
      tags 'Medical History'
      security [ basic: [] ]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      parameter name: 'HTTP_X_FACILITY_ID', in: :header, type: :uuid
      parameter name: :medical_histories, in: :body, schema: Api::Current::Schema.medical_history_sync_from_user_request

      response '200', 'medical_histories created' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        let(:medical_histories) { { medical_histories: (1..10).map { build_medical_history_payload_current } } }

        run_test!
      end

      response '200', 'some, or no errors were found' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::Current::Schema.sync_from_user_errors
        let(:medical_histories) { { medical_histories: (1..10).map { build_invalid_medical_history_payload_current } } }
        run_test!
      end
    end

    get 'Syncs medical_history data from server to device.' do
      tags 'Medical History'
      security [ basic: [] ]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      parameter name: 'HTTP_X_FACILITY_ID', in: :header, type: :uuid
      Api::Current::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          FactoryBot.create_list(:medical_history, 10)
        end
      end

      response '200', 'medical_histories received' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::Current::Schema.medical_history_sync_to_user_response
        let(:processed_since) { 10.minutes.ago }
        let(:limit) { 10 }
        before do |example|
          submit_request(example.metadata)
        end

        it 'returns a valid 201 response' do |example|
          assert_response_matches_metadata(example.metadata)
        end
      end
    end
  end
end
