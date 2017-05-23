function [ Chinese ] = isChinese( ch )
% ����GB2312���ַ�����������ƽʱ��˵����λ����һ�����ֶ�Ӧ�������ֽڡ� ÿ���ֽڶ��Ǵ���A0��ʮ������,��160����
% ��������һ���ֽڴ���A0�����ڶ����ֽ�С��A0����ô��Ӧ�����Ǻ��֣���������GB2312)
Chinese=zeros(size(ch),'logical');
for i=1:size(ch,1)
    for j=1:size(ch,2)
        info = unicode2native(ch(i,j));
        bytes = size(info,2);
        if (bytes == 2)
            Chinese(i,j) = 1;
        end
    end
end

