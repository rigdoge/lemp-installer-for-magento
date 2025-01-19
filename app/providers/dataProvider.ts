import { DataProvider, CreateParams, CreateResult, DeleteParams, DeleteResult, RaRecord, Identifier } from 'react-admin';

export const dataProvider: DataProvider = {
  getList: async (resource, params) => {
    const { page, perPage } = params.pagination;
    const { field, order } = params.sort;
    const { q, ...filters } = params.filter;

    const response = await fetch(`/api/${resource}?page=${page}&perPage=${perPage}`);
    const json = await response.json();

    return {
      data: json.data,
      total: json.total,
    };
  },

  getOne: async (resource, params) => {
    const response = await fetch(`/api/${resource}/${params.id}`);
    const json = await response.json();

    return {
      data: json,
    };
  },

  getMany: async (resource, params) => {
    const response = await fetch(`/api/${resource}?ids=${params.ids.join(',')}`);
    const json = await response.json();

    return {
      data: json,
    };
  },

  getManyReference: async (resource, params) => {
    const { page, perPage } = params.pagination;
    const { field, order } = params.sort;
    
    const response = await fetch(
      `/api/${resource}?target=${params.target}&id=${params.id}&page=${page}&perPage=${perPage}`
    );
    const json = await response.json();

    return {
      data: json.data,
      total: json.total,
    };
  },

  create: async <RecordType extends RaRecord = any>(
    resource: string,
    params: CreateParams<RecordType>
  ): Promise<CreateResult<RecordType>> => {
    const response = await fetch(`/api/${resource}`, {
      method: 'POST',
      body: JSON.stringify(params.data),
      headers: {
        'Content-Type': 'application/json',
      },
    });
    const json = await response.json();

    return {
      data: { ...params.data, id: json.id } as RecordType,
    };
  },

  update: async (resource, params) => {
    const response = await fetch(`/api/${resource}/${params.id}`, {
      method: 'PUT',
      body: JSON.stringify(params.data),
      headers: {
        'Content-Type': 'application/json',
      },
    });
    const json = await response.json();

    return {
      data: json,
    };
  },

  updateMany: async (resource, params) => {
    const response = await fetch(`/api/${resource}`, {
      method: 'PUT',
      body: JSON.stringify({ ids: params.ids, data: params.data }),
      headers: {
        'Content-Type': 'application/json',
      },
    });
    const json = await response.json();

    return {
      data: json,
    };
  },

  delete: async <RecordType extends RaRecord = any>(
    resource: string,
    params: DeleteParams<RecordType>
  ): Promise<DeleteResult<RecordType>> => {
    await fetch(`/api/${resource}/${params.id}`, {
      method: 'DELETE',
    });

    return {
      data: params.previousData as RecordType,
    };
  },

  deleteMany: async (resource, params) => {
    await fetch(`/api/${resource}`, {
      method: 'DELETE',
      body: JSON.stringify({ ids: params.ids }),
      headers: {
        'Content-Type': 'application/json',
      },
    });

    return {
      data: [],
    };
  },
}; 