module ApplicationHelper
  def simple_pagination(pagination)
    return "".html_safe unless pagination && pagination.total_pages > 1

    content_tag(:nav, aria: { label: "Pagination" }) do
      content_tag(:ul, class: "pagination pagination-sm mt-3 mb-0") do
        prev_link = content_tag(:li, class: "page-item #{'disabled' unless pagination.prev_page}") do
          link_to("Previous", url_for(request.query_parameters.merge(page: pagination.prev_page)), class: "page-link")
        end

        page_info = content_tag(:li, class: "page-item disabled") do
          content_tag(:span, "Page #{pagination.page} of #{pagination.total_pages}", class: "page-link")
        end

        next_link = content_tag(:li, class: "page-item #{'disabled' unless pagination.next_page}") do
          link_to("Next", url_for(request.query_parameters.merge(page: pagination.next_page)), class: "page-link")
        end

        safe_join([prev_link, page_info, next_link])
      end
    end
  end
end
