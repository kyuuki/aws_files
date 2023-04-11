#!/bin/bash
#
# 自分の IP アドレスを特定の FQND に割り当て
#
# - cron で起動時に一度だけ実行
#   (例) @reboot /home/ec2-user/bin/upsert_route53.sh Z3T2KC0KGMQA00 >> $HOME/upsert_route53.log
# - ドメイン (HOSTED_ZONE_ID) はパタメータで指定 (デフォルトは akoba.xyz の HOSTED_ZONE_ID)
# - ホスト名はインスタンスのタグ名 (typename) から取得
# - https://atmarkit.itmedia.co.jp/aig/06network/fqdn.html
#
# - AWS CLI は設定済みの前提
#

# 引数チェック (数のみ)
# - https://bioinfo-dojo.net/2018/02/21/shellscript_args/#toc2
if [ $# != 1 ]; then
    echo >&2 "ERROR: Args count error."
    exit 1
fi

# 以下で HOSTED_ZONE_ID を確認
# https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones
# aws route53 list-hosted-zones 
#HOSTED_ZONE_ID="Z3T2KC0KGMQA00"  # akoba.xyz
HOSTED_ZONE_ID=$1

# タグ名 (typename) 取得
# - https://qiita.com/JunkiHiroi/items/0e63a9d551d5dafa34d2
# - https://qiita.com/qtatsunishiura/items/fdd5e7f251299a90cd8c#%E5%89%8D%E7%BD%AE%E3%81%8D-%E5%A4%89%E6%95%B0%E5%B1%95%E9%96%8B%E3%82%92%E4%BD%BF%E3%82%8F%E3%81%9A%E7%9B%B4%E6%8E%A5%E5%80%A4%E3%82%92%E6%9B%B8%E3%81%8F%E5%A0%B4%E5%90%88
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
# エラー処理は甘め。エラー HTML が取得される場合は検出できない。
echo $?
echo $INSTANCE_ID

TYPENAME=$(aws ec2 describe-instances --instance-ids "${INSTANCE_ID}" --query 'Reservations[0].Instances[0].Tags[?Key==`typename`]|[0].Value' | tr -d '"')
# エラー処理は甘め。tr コマンドの終了ステータスになる。
echo $?
echo $TYPENAME

# ドメイン取得
DOMAIN=$(aws route53 get-hosted-zone --id $HOSTED_ZONE_ID --query "HostedZone.Name" | tr -d '"')
# エラー処理は甘め。tr コマンドの終了ステータスになる。
echo $?
echo $DOMAIN

FQDN="$TYPENAME.$DOMAIN"
echo $FQDN

IPV4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
# エラー処理は甘め。エラー HTML が取得される場合は検出できない。
echo $?
echo $IPV4

# 一時ファイルは消さない
tmpfile=$(mktemp)

cat <<EOF > $tmpfile
{
  "Comment": "UPSERT a record ",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$FQDN",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{ "Value": "$IPV4" }]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://$tmpfile
# ↓ココまではしない
# https://hacknote.jp/archives/35775/
if [ $? -ne 0 ]; then
    echo >&2 "ERROR: aws route53 command error."
    exit 1
fi
