import { NextResponse } from 'next/server';
import { Client } from '@opensearch-project/opensearch';
import { SearchResponse } from '@opensearch-project/opensearch/api/types';

interface LogEntry {
  id: string;
  timestamp: string;
  level: string;
  source: string;
  message: string;
}

// OpenSearch 客户端配置
const client = new Client({
  node: process.env.OPENSEARCH_NODE || 'https://localhost:9200',
  auth: {
    username: process.env.OPENSEARCH_USERNAME || 'admin',
    password: process.env.OPENSEARCH_PASSWORD || 'admin',
  },
  ssl: {
    rejectUnauthorized: false // 开发环境使用自签名证书
  }
});

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const page = parseInt(searchParams.get('page') || '1');
  const perPage = parseInt(searchParams.get('perPage') || '25');
  const source = searchParams.get('source');
  const level = searchParams.get('level');
  const q = searchParams.get('q');

  try {
    // 构建 OpenSearch 查询
    const query: any = {
      bool: {
        must: []
      }
    };

    if (source) {
      query.bool.must.push({ term: { source } });
    }

    if (level) {
      query.bool.must.push({ term: { level } });
    }

    if (q) {
      query.bool.must.push({
        multi_match: {
          query: q,
          fields: ['message', 'source', 'level']
        }
      });
    }

    // 执行 OpenSearch 查询
    const response = await client.search<LogEntry>({
      index: 'logs',
      body: {
        query,
        sort: [{ timestamp: { order: 'desc' } }],
        from: (page - 1) * perPage,
        size: perPage,
      },
    });

    const hits = response.body?.hits?.hits || [];
    const total = typeof response.body?.hits?.total === 'number' 
      ? response.body.hits.total 
      : response.body?.hits?.total?.value || 0;

    // 格式化响应数据
    const data = hits.map(hit => ({
      id: hit._id,
      ...hit._source,
    }));

    return NextResponse.json({
      data,
      total,
    });

  } catch (error) {
    console.error('OpenSearch query error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch logs' },
      { status: 500 }
    );
  }
} 