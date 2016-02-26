# encoding: utf-8
module Spotlight
  module Resources
    ##
    # Exhibit-specific resources, created using uploaded and custom fields
    class Videoupload < Spotlight::Resource
	  Rails.logger.warn("In object videoupload.rb line 7 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
      mount_uploader :url, Spotlight::VideoItemUploader
	  Rails.logger.warn("In object videoupload.rb line 9 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
     # include Spotlight::ImageDerivatives
	  Rails.logger.warn("In object videoupload.rb line 11 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
      # we want to do this before reindexing
      after_create :update_document_sidecar

      def self.fields(exhibit)
        @fields ||= {}
        @fields[exhibit] ||= begin
          title_field = Spotlight::Engine.config.upload_title_field || OpenStruct.new(field_name: exhibit.blacklight_config.index.title_field)
          [title_field] + exhibit.uploaded_resource_fields
        end
      end

      def configured_fields
        self.class.fields(exhibit)
      end

      def to_solr
        store_url! # so that #url doesn't return the tmp directory

        solr_hash = super
Rails.logger.warn("In object videoupload.rb line 31 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
        add_default_solr_fields solr_hash
Rails.logger.warn("In object videoupload.rb line 33 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
        #add_image_dimensions solr_hash
Rails.logger.warn("In object videoupload.rb line 35 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
        add_file_versions solr_hash
Rails.logger.warn("In object videoupload.rb line 37 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
        add_sidecar_fields solr_hash
Rails.logger.warn("In object videoupload.rb line 39 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
        solr_hash
      end

      private

      def add_default_solr_fields(solr_hash)
        solr_hash[exhibit.blacklight_config.document_model.unique_key.to_sym] = compound_id
		solr_hash[Spotlight::Engine.config.full_image_field] = "#{url}"
		if "#{url}".end_with? "mp4"
			solr_hash["thumbnail_url_ssm"] = "/uploads/spotlight/resources/videoupload/url/stock.jpg"
		else
			solr_hash["thumbnail_url_ssm"] = "/uploads/spotlight/resources/videoupload/url/stockaudio.jpg"
		end
	  end

      def add_image_dimensions(solr_hash)
        dimensions = ::MiniMagick::Image.open(url.file.file)[:dimensions]
        solr_hash[:spotlight_full_image_width_ssm] = nil
        solr_hash[:spotlight_full_image_height_ssm] = nil
      end

      def add_file_versions(solr_hash)
Rails.logger.warn("In object videoupload.rb add_file_versions line 56 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
      end

      def add_sidecar_fields(solr_hash)
        solr_hash.merge! sidecar.to_solr
      end

      def compound_id
        "#{exhibit_id}-#{id}"
      end

      def update_document_sidecar
Rails.logger.warn("In object videoupload.rb line 74 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
        sidecar.update(data: sidecar.data.merge(sidecar_update_data))
Rails.logger.warn("In object videoupload.rb line 76 AT:"+Time.now.strftime("%m%d %H:%M:%S:%L")+"")
      end

      def sidecar_update_data
        custom_fields_data.merge('configured_fields' => configured_fields_data)
      end

      def custom_fields_data
        data.slice(*exhibit.custom_fields.map(&:field).map(&:to_s)).select { |_k, v| v.present? }
      end

      def configured_fields_data
        data.slice(*configured_fields.map(&:field_name).map(&:to_s)).select { |_k, v| v.present? }
      end

      def sidecar
        @sidecar ||= document_model.new(id: compound_id).sidecar(exhibit)
      end
    end
  end
end
