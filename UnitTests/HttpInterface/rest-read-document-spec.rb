# coding: utf-8

require 'rspec'
require './arangodb.rb'

describe ArangoDB do
  prefix = "rest-read-document"

  context "reading a document:" do
 
  before do  
    @rePath = Regexp.new('^/_api/document/[a-zA-Z0-9_\-]+/\d+$')
    @reFull = Regexp.new('^[a-zA-Z0-9_\-]+/\d+$')
    @reRev  = Regexp.new('^[0-9]+$')
  end

################################################################################
## error handling
################################################################################

    context "error handling:" do
      before do
        @cn = "UnitTestsCollectionBasics"
        @cid = ArangoDB.create_collection(@cn)
      end

      after do
        ArangoDB.drop_collection(@cn)
      end

      it "returns an error if document handle is corrupted" do
        cmd = "/_api/document/123456"
        doc = ArangoDB.log_get("#{prefix}-bad-handle", cmd)

        doc.code.should eq(400)
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['errorNum'].should eq(1205)
        doc.parsed_response['code'].should eq(400)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
      end

      it "returns an error if document handle is corrupted with empty cid" do
        cmd = "/_api/document//123456"
        doc = ArangoDB.log_get("#{prefix}-bad-handle2", cmd)

        doc.code.should eq(400)
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['errorNum'].should eq(1203)
        doc.parsed_response['code'].should eq(400)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
      end

      it "returns an error if collection identifier is unknown" do
        cmd = "/_api/document/123456/234567"
        doc = ArangoDB.log_get("#{prefix}-unknown-cid", cmd)

        doc.code.should eq(404)
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['errorNum'].should eq(1203)
        doc.parsed_response['code'].should eq(404)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
      end

      it "returns an error if document handle is unknown" do
        cmd = "/_api/document/#{@cid}/234567"
        doc = ArangoDB.log_get("#{prefix}-unknown-handle", cmd)

        doc.code.should eq(404)
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['errorNum'].should eq(1202)
        doc.parsed_response['code'].should eq(404)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")

        ArangoDB.size_collection(@cid).should eq(0)
      end
    end

################################################################################
## reading documents
################################################################################

    context "reading a document:" do
      before do
        @cn = "UnitTestsCollectionBasics"
        @cid = ArangoDB.create_collection(@cn)
      end

      after do
        ArangoDB.drop_collection(@cn)
      end

      it "create a document and read it" do
        cmd = "/_api/document?collection=#{@cid}"
        body = "{ \"Hallo\" : \"World\" }"
        doc = ArangoDB.post(cmd, :body => body)

        doc.code.should eq(201)

        location = doc.headers['location']
        location.should be_kind_of(String)

        did = doc.parsed_response['_id']
        
        did.should match(@reFull)
        did.should start_with(@cn + "/")
        
        rev = doc.parsed_response['_rev']
        rev.should match(@reRev)

        # get document
        cmd = "/_api/document/#{did}"
        doc = ArangoDB.log_get("#{prefix}", cmd)

        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")

        did2 = doc.parsed_response['_id']
        did2.should be_kind_of(String)
        did2.should match(@reFull)
        did2.should start_with(@cn + "/")
        did2.should eq(did)
        
        rev2 = doc.parsed_response['_rev']
        rev2.should be_kind_of(String)
        rev2.should match(@reRev)
        rev2.should eq(rev)

        etag = doc.headers['etag']
        etag.should be_kind_of(String)

        etag.should eq("\"#{rev}\"")

        ArangoDB.delete(location)

        ArangoDB.size_collection(@cid).should eq(0)
      end

      it "create a document and read it, using collection name" do
        cmd = "/_api/document?collection=#{@cn}"
        body = "{ \"Hallo\" : \"World\" }"
        doc = ArangoDB.post(cmd, :body => body)

        doc.code.should eq(201)

        location = doc.headers['location']
        location.should be_kind_of(String)

        did = doc.parsed_response['_id']
        did.should match(@reFull)
        did.should start_with(@cn + "/")

        rev = doc.parsed_response['_rev']
        rev.should match(@reRev)

        # get document
        cmd = "/_api/document/#{did}"
        doc = ArangoDB.log_get("#{prefix}", cmd)

        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")

        did2 = doc.parsed_response['_id']
        did2.should be_kind_of(String)
        did2.should match(@reFull)
        did2.should start_with(@cn + "/")
        did2.should eq(did)
        
        rev2 = doc.parsed_response['_rev']
        rev2.should be_kind_of(String)
        rev2.should match(@reRev)
        rev2.should eq(rev)

        etag = doc.headers['etag']
        etag.should be_kind_of(String)

        etag.should eq("\"#{rev}\"")

        ArangoDB.delete(location)

        ArangoDB.size_collection(@cid).should eq(0)
      end

      it "create a document and read it, use if-none-match" do
        cmd = "/_api/document?collection=#{@cid}"
        body = "{ \"Hallo\" : \"World\" }"
        doc = ArangoDB.post(cmd, :body => body)

        doc.code.should eq(201)

        location = doc.headers['location']
        location.should be_kind_of(String)

        did = doc.parsed_response['_id']
        did.should match(@reFull)
        did.should start_with(@cn + "/")

        rev = doc.parsed_response['_rev']
        rev.should match(@reRev)

        # get document, if-none-match with same rev
        cmd = "/_api/document/#{did}"
        hdr = { "if-none-match" => "\"#{rev}\"" }
        doc = ArangoDB.log_get("#{prefix}-if-none-match", cmd, :headers => hdr)

        doc.code.should eq(304)

        etag = doc.headers['etag']
        etag.should be_kind_of(String)

        etag.should eq("\"#{rev}\"")

        # get document, if-none-match with different rev
        cmd = "/_api/document/#{did}"
        hdr = { "if-none-match" => "\"54454#{rev}\"" }
        doc = ArangoDB.log_get("#{prefix}-if-none-match-other", cmd, :headers => hdr)

        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")

        etag = doc.headers['etag']
        etag.should be_kind_of(String)

        etag.should eq("\"#{rev}\"")

        did2 = doc.parsed_response['_id']
        did2.should be_kind_of(String)
        did2.should match(@reFull)
        did2.should start_with(@cn + "/")
        did2.should eq(did)
        
        rev2 = doc.parsed_response['_rev']
        rev2.should be_kind_of(String)
        rev2.should match(@reRev)
        rev2.should eq(rev)

        etag = doc.headers['etag']
        etag.should be_kind_of(String)

        etag.should eq("\"#{rev}\"")

        ArangoDB.delete(location)

        ArangoDB.size_collection(@cid).should eq(0)
      end

      it "create a document and read it, use if-match" do
        cmd = "/_api/document?collection=#{@cid}"
        body = "{ \"Hallo\" : \"World\" }"
        doc = ArangoDB.post(cmd, :body => body)

        doc.code.should eq(201)

        location = doc.headers['location']
        location.should be_kind_of(String)

        did = doc.parsed_response['_id']
        did.should match(@reFull)
        did.should start_with(@cn + "/")

        rev = doc.parsed_response['_rev']
        rev.should match(@reRev)

        # get document, if-match with same rev
        cmd = "/_api/document/#{did}"
        hdr = { "if-match" => "\"#{rev}\"" }
        doc = ArangoDB.log_get("#{prefix}-if-match", cmd, :headers => hdr)

        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")

        did2 = doc.parsed_response['_id']
        did2.should be_kind_of(String)
        did2.should match(@reFull) 
        did2.should start_with(@cn + "/")
        did2.should eq(did)
        
        rev2 = doc.parsed_response['_rev']
        rev2.should be_kind_of(String)
        rev2.should match(@reRev) 
        rev2.should eq(rev)

        etag = doc.headers['etag']
        etag.should be_kind_of(String)

        etag.should eq("\"#{rev}\"")

        # get document, if-match with different rev
        cmd = "/_api/document/#{did}"
        hdr = { "if-match" => "\"348574#{rev}\"" }
        doc = ArangoDB.log_get("#{prefix}-if-match-other", cmd, :headers => hdr)

        doc.code.should eq(412)

        did2 = doc.parsed_response['_id']
        did2.should be_kind_of(String)
        did2.should match(@reFull) 
        did2.should start_with(@cn + "/")
        did2.should eq(did)
        
        rev2 = doc.parsed_response['_rev']
        rev2.should be_kind_of(String)
        rev2.should match(@reRev)
        rev2.should eq(rev)

        ArangoDB.delete(location)

        ArangoDB.size_collection(@cid).should eq(0)
      end
    end

################################################################################
## reading all documents
################################################################################

    context "reading all documents:" do
      before do
        @cn = "UnitTestsCollectionAll"
        @cid = ArangoDB.create_collection(@cn)
      end

      after do
        ArangoDB.drop_collection(@cn)
      end

      it "get all documents of an empty collection" do
        cmd = "/_api/document?collection=#{@cid}"

        # get documents
        cmd = "/_api/document?collection=#{@cid}"
        doc = ArangoDB.log_get("#{prefix}-all-0", cmd)

        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")

        documents = doc.parsed_response['documents']
        documents.should be_kind_of(Array)
        documents.length.should eq(0)

        ArangoDB.size_collection(@cid).should eq(0)
      end

      it "create three documents and read them using the collection identifier" do
        cmd = "/_api/document?collection=#{@cid}"

        location = []

        for i in [ 1, 2, 3 ]
          body = "{ \"Hallo\" : \"World-#{i}\" }"
          doc = ArangoDB.post(cmd, :body => body)

          doc.code.should eq(201)

          location.push(doc.headers['location'])
        end

        # get document
        cmd = "/_api/document?collection=#{@cid}"
        doc = ArangoDB.log_get("#{prefix}-all", cmd)

        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")

        documents = doc.parsed_response['documents']
        documents.should be_kind_of(Array)
        documents.length.should eq(3)

        documents.each { |document|
          document.should match(@rePath)
          document.should start_with("/_api/document/" + @cn + "/")
        }

        for l in location
          ArangoDB.delete(l)
        end

        ArangoDB.size_collection(@cid).should eq(0)
      end

      it "create three documents and read them using the collection name" do
        cmd = "/_api/document?collection=#{@cn}"

        location = []

        for i in [ 1, 2, 3 ]
          body = "{ \"Hallo\" : \"World-#{i}\" }"
          doc = ArangoDB.post(cmd, :body => body)

          doc.code.should eq(201)

          location.push(doc.headers['location'])
        end

        # get document
        cmd = "/_api/document?collection=#{@cn}"
        doc = ArangoDB.log_get("#{prefix}-all-name", cmd)

        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")

        documents = doc.parsed_response['documents']
        documents.should be_kind_of(Array)
        documents.length.should eq(3)
        
        documents.each { |document|
          document.should match(@rePath)
          document.should start_with("/_api/document/" + @cn + "/")
        }

        for l in location
          ArangoDB.delete(l)
        end

        ArangoDB.size_collection(@cid).should eq(0)
      end
    end

################################################################################
## checking document
################################################################################

    context "checking a document:" do
      before do
        @cn = "UnitTestsCollectionBasics"
        @cid = ArangoDB.create_collection(@cn)
      end

      after do
        ArangoDB.drop_collection(@cn)
      end

      it "create a document and read it" do
        cmd = "/_api/document?collection=#{@cid}"
        body = "{ \"Hallo\" : \"World\" }"
        doc = ArangoDB.post(cmd, :body => body)

        doc.code.should eq(201)
        location = doc.headers['location']
        location.should be_kind_of(String)

        # get document
        cmd = location
        doc = ArangoDB.log_get("#{prefix}-head", cmd)

        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")

        content_length = doc.headers['content-length']

        # get the document head
        doc = ArangoDB.head(cmd)

        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")

        doc.headers['content-length'].should eq(content_length)
        doc.body.should eq(nil)

        ArangoDB.delete(location)

        ArangoDB.size_collection(@cid).should eq(0)
      end
    end

  end
end
